import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

vi.mock('@/services/auth', () => ({
  getBCAccessToken: vi.fn().mockResolvedValue('token'),
}));

import { bcClient } from '@/services/bc/bcClient';

function stubFetch(status: number, body: unknown) {
  const fetchMock = vi.fn(async () => ({
    ok: status >= 200 && status < 300,
    status,
    json: async () => body,
    text: async () => JSON.stringify(body),
  }));
  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}

describe('bcClient.getJobCostEntries', () => {
  beforeEach(() => {
    bcClient.setCompany('00000000-0000-0000-0000-0000000000c3', 'sandbox');
    // Forget an earlier test's 404 (the client is shared)
    bcClient.resetExtensionCache();
    vi.spyOn(bcClient, 'isExtensionInstalled').mockResolvedValue(true);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.mocked(bcClient.isExtensionInstalled).mockRestore();
  });

  it("reads every entry type for the project and decodes BC's G/L Account encoding", async () => {
    const fetchMock = stubFetch(200, {
      value: [
        { id: 'e1', jobNo: 'PR-CONTOSO', type: 'Resource', quantity: 8 },
        { id: 'e2', jobNo: 'PR-CONTOSO', type: 'G_x002F_L_x0020_Account', quantity: 1 },
      ],
    });

    const entries = await bcClient.getJobCostEntries('PR-CONTOSO');

    expect(entries?.map((e) => e.type)).toEqual(['Resource', 'G/L Account']);
    const url = String((fetchMock.mock.calls[0] as unknown[])[0]);
    expect(url).toContain('/jobCostEntries?$filter=');
    expect(decodeURIComponent(url)).toContain("jobNo eq 'PR-CONTOSO'");
  });

  it('returns null on an extension without the endpoint (404), so the caller uses timeEntries', async () => {
    stubFetch(404, { error: { message: 'No HTTP resource was found' } });
    await expect(bcClient.getJobCostEntries('PR-CONTOSO')).resolves.toBeNull();
  });

  it('remembers the 404 for the company, so the next project load asks only timeEntries', async () => {
    const fetchMock = stubFetch(404, { error: { message: 'No HTTP resource was found' } });
    await bcClient.getJobCostEntries('PR-CONTOSO');
    await expect(bcClient.getJobCostEntries('PR-OTHER')).resolves.toBeNull();
    expect(fetchMock).toHaveBeenCalledTimes(1);

    // Another company may have the updated extension: ask again
    bcClient.setCompany('00000000-0000-0000-0000-0000000000c4', 'sandbox');
    await bcClient.getJobCostEntries('PR-CONTOSO');
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it("doesn't remember a 404 that arrives after the company has changed", async () => {
    let answer404!: () => void;
    const fetchMock = vi.fn(
      () =>
        new Promise((resolve) => {
          answer404 = () =>
            resolve({ ok: false, status: 404, json: async () => ({}), text: async () => '' });
        })
    );
    vi.stubGlobal('fetch', fetchMock);
    const stale = bcClient.getJobCostEntries('PR-CONTOSO');
    await vi.waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));
    // The user switches company while the old company's request is in flight
    bcClient.setCompany('00000000-0000-0000-0000-0000000000c4', 'sandbox');
    answer404();
    await expect(stale).resolves.toBeNull();

    // The new company is still asked for its own jobCostEntries
    stubFetch(200, { value: [] });
    await expect(bcClient.getJobCostEntries('PR-CONTOSO')).resolves.toEqual([]);
  });

  it('throws on any other error (e.g. 500), rather than fall back to Resource-only costs', async () => {
    stubFetch(500, { error: { message: 'Internal error' } });
    await expect(bcClient.getJobCostEntries('PR-CONTOSO')).rejects.toThrow('(500)');
  });

  it('throws on a 401 too, and asks again next time', async () => {
    const fetchMock = stubFetch(401, { error: { message: 'Unauthorized' } });
    await expect(bcClient.getJobCostEntries('PR-CONTOSO')).rejects.toThrow('(401)');
    await expect(bcClient.getJobCostEntries('PR-CONTOSO')).rejects.toThrow('(401)');
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
});
