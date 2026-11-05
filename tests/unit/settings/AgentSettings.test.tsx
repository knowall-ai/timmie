import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import toast from 'react-hot-toast';

vi.mock('react-hot-toast', () => ({ default: { success: vi.fn(), error: vi.fn() } }));

const api = vi.hoisted(() => ({ fetchOrgSettings: vi.fn(), saveAgentSettings: vi.fn() }));
vi.mock('@/services/settings/orgSettingsService', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/services/settings/orgSettingsService')>();
  return {
    ...actual,
    fetchOrgSettings: () => api.fetchOrgSettings(),
    saveAgentSettings: (agent: unknown) => api.saveAgentSettings(agent),
  };
});

import { AgentSettings } from '@/components/settings/AgentSettings';
import { useAgentSettingsStore } from '@/hooks/useAgentSettingsStore';
import { OrgSettingsError } from '@/services/settings/orgSettingsService';
import { TIMMIE_AGENT } from '@/utils/agentSettings';

const CONTOSO_BOT = { kind: 'custom', name: 'Contoso Bot' } as const;

describe('AgentSettings', () => {
  beforeEach(() => {
    api.fetchOrgSettings.mockReset();
    api.saveAgentSettings.mockReset();
    vi.mocked(toast.success).mockReset();
    vi.spyOn(console, 'warn').mockImplementation(() => {});
    useAgentSettingsStore.setState({
      agent: TIMMIE_AGENT,
      canEdit: false,
      canSave: true,
      loaded: false,
      loadError: null,
    });
  });

  /** Renders the card for an administrator with the given agent already saved */
  async function renderAsAdmin(agent: { kind: 'timmie' | 'custom'; name: string } = TIMMIE_AGENT) {
    api.fetchOrgSettings.mockResolvedValue({ agent, canEdit: true, canSave: true });
    render(<AgentSettings />);
    await screen.findByRole('button', { name: 'Save' });
  }

  it('says why the settings did not load, and tries again', async () => {
    api.fetchOrgSettings.mockRejectedValueOnce(
      new OrgSettingsError('Settings are unavailable right now (503).')
    );
    render(<AgentSettings />);
    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Settings are unavailable right now (503).'
    );

    api.fetchOrgSettings.mockResolvedValueOnce({
      agent: CONTOSO_BOT,
      canEdit: true,
      canSave: true,
    });
    fireEvent.click(screen.getByRole('button', { name: 'Try again' }));
    await waitFor(() => expect(screen.getByLabelText('Agent name')).toHaveValue('Contoso Bot'));
  });

  it("tells an administrator when the server can't save settings", async () => {
    api.fetchOrgSettings.mockResolvedValue({ agent: TIMMIE_AGENT, canEdit: true, canSave: false });
    render(<AgentSettings />);
    expect(await screen.findByText(/has no settings storage set up/)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Save' })).not.toBeInTheDocument();
    expect(screen.getByRole('radio', { name: /Your own agent/ })).toBeDisabled();
  });

  it('saves a custom agent, tidied, and tells everyone the new name', async () => {
    await renderAsAdmin();
    expect(screen.getByRole('button', { name: 'Save' })).toBeDisabled(); // nothing changed yet

    fireEvent.click(screen.getByRole('radio', { name: /Your own agent/ }));
    fireEvent.change(screen.getByLabelText('Agent name'), {
      target: { value: '  Contoso   Bot ' },
    });
    api.saveAgentSettings.mockResolvedValue({ agent: CONTOSO_BOT, canEdit: true, canSave: true });
    fireEvent.click(screen.getByRole('button', { name: 'Save' }));

    await waitFor(() => expect(useAgentSettingsStore.getState().agent).toEqual(CONTOSO_BOT));
    expect(api.saveAgentSettings).toHaveBeenCalledWith(CONTOSO_BOT);
    expect(toast.success).toHaveBeenCalledWith('Timmie now works with Contoso Bot');
    expect(screen.getByLabelText('Agent name')).toHaveValue('Contoso Bot');
  });

  it("switches back to Timmie's own agent", async () => {
    await renderAsAdmin(CONTOSO_BOT);
    fireEvent.click(screen.getByRole('radio', { name: /^Timmie/ }));
    api.saveAgentSettings.mockResolvedValue({ agent: TIMMIE_AGENT, canEdit: true, canSave: true });
    fireEvent.click(screen.getByRole('button', { name: 'Save' }));

    await waitFor(() => expect(useAgentSettingsStore.getState().agent).toEqual(TIMMIE_AGENT));
    expect(api.saveAgentSettings).toHaveBeenCalledWith(TIMMIE_AGENT);
    expect(toast.success).toHaveBeenCalledWith('Timmie now uses its own agent');
  });

  it("explains an invalid name and won't save it", async () => {
    await renderAsAdmin();
    fireEvent.click(screen.getByRole('radio', { name: /Your own agent/ }));
    const input = screen.getByLabelText('Agent name');

    fireEvent.change(input, { target: { value: '1abc' } });
    expect(screen.getByText(/Start with a letter/)).toBeInTheDocument();
    expect(input).toHaveAttribute('aria-invalid', 'true');
    expect(screen.getByRole('button', { name: 'Save' })).toBeDisabled();

    fireEvent.change(input, { target: { value: '' } });
    expect(screen.queryByText(/Start with a letter/)).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Save' })).toBeDisabled();
    expect(api.saveAgentSettings).not.toHaveBeenCalled();
  });

  it("shows the server's refusal and keeps the saved agent", async () => {
    await renderAsAdmin();
    fireEvent.click(screen.getByRole('radio', { name: /Your own agent/ }));
    fireEvent.change(screen.getByLabelText('Agent name'), { target: { value: 'Contoso Bot' } });
    api.saveAgentSettings.mockRejectedValue(
      new OrgSettingsError('Only Timmie administrators can change this.')
    );
    fireEvent.click(screen.getByRole('button', { name: 'Save' }));

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Only Timmie administrators can change this.'
    );
    expect(useAgentSettingsStore.getState().agent).toEqual(TIMMIE_AGENT);
    expect(toast.success).not.toHaveBeenCalled();
    expect(screen.getByRole('button', { name: 'Save' })).toBeEnabled(); // can try again
  });
});
