import { describe, it, expect, vi, beforeEach } from 'vitest';

const client = vi.hoisted(() => ({
  isExtensionInstalled: vi.fn(async () => true),
  getResources: vi.fn(),
  getTimeSheetsFrom: vi.fn(),
  getTimeSheetLinesForJob: vi.fn(),
  getTimeSheetDetailsForJob: vi.fn(),
  getJobPlanningLines: vi.fn(async () => []),
  getResourceUnitsOfMeasure: vi.fn(async () => []),
  getTimeEntries: vi.fn(async () => []),
  getJobTasks: vi.fn(async () => []),
}));
vi.mock('@/services/bc/bcClient', () => ({ bcClient: client }));

import { projectDetailsService } from '@/services/bc/projectDetailsService';

beforeEach(() => {
  vi.clearAllMocks();
  client.getResources.mockResolvedValue([{ number: 'R0010', name: 'Contoso Person' }]);
  client.getTimeSheetsFrom.mockResolvedValue([{ number: 'TS001', resourceNo: 'R0010' }]);
  // An approved line on task 100 (partly posted) and an open one on task 200
  client.getTimeSheetLinesForJob.mockResolvedValue([
    {
      timeSheetNo: 'TS001',
      lineNo: 10000,
      type: 'Job',
      jobNo: 'PR00010',
      jobTaskNo: '100',
      totalQuantity: 10,
      status: 'Approved',
      chargeable: true,
    },
    {
      timeSheetNo: 'TS001',
      lineNo: 20000,
      type: 'Job',
      jobNo: 'PR00010',
      jobTaskNo: '200',
      totalQuantity: 3,
      status: 'Open',
      chargeable: true,
    },
  ]);
  // The approved line spans the end of September into October
  client.getTimeSheetDetailsForJob.mockResolvedValue([
    {
      timeSheetNo: 'TS001',
      timeSheetLineNo: 10000,
      date: '2026-09-30',
      quantity: 6,
      postedQuantity: 6,
    },
    { timeSheetNo: 'TS001', timeSheetLineNo: 10000, date: '2026-10-01', quantity: 4 },
    { timeSheetNo: 'TS001', timeSheetLineNo: 20000, date: '2026-10-02', quantity: 3 },
  ]);
});

describe('project analytics by month', () => {
  it('splits each month by stage and task, oldest month first', async () => {
    const a = await projectDetailsService.getProjectAnalytics('PR00010');

    expect(a.monthBreakdown.map((m) => m.month)).toEqual(['2026-09', '2026-10']);

    const [september, october] = a.monthBreakdown;
    expect(september).toMatchObject({ hours: 6, postedHours: 6, approvedHours: 0 });
    expect(october).toMatchObject({
      hours: 7,
      postedHours: 0,
      approvedHours: 4,
      unsubmittedHours: 3,
    });
    expect(october.tasks).toEqual([
      expect.objectContaining({ taskNo: '100', hours: 4, approvedHours: 4 }),
      expect.objectContaining({ taskNo: '200', hours: 3, unsubmittedHours: 3 }),
    ]);

    // The months add up to the project's whole breakdown
    for (const key of ['hours', 'postedHours', 'approvedHours'] as const) {
      const byMonth = a.monthBreakdown.reduce((sum, m) => sum + m[key], 0);
      const byTask = a.taskBreakdown.reduce((sum, t) => sum + t[key], 0);
      expect(byMonth).toBe(byTask);
    }
  });
});
