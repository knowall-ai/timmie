import { describe, expect, it } from 'vitest';
import {
  filterRows,
  MAX_TOP,
  ODataQueryError,
  orderRows,
  queryRows,
} from '@/services/demo/odataQuery';

const rows = [
  { no: 'A', date: '2026-10-19', hours: 8, type: 'Job', submitted: true, name: "O'Brien" },
  { no: 'B', date: '2026-10-20', hours: 4.5, type: 'Job', submitted: false, name: 'Shah' },
  { no: 'C', date: '2026-10-26', hours: 0, type: 'Absence', submitted: false, name: 'Chen' },
];
const nos = (result: { no: string }[]) => result.map((r) => r.no);

describe('demo OData filters', () => {
  it('compares strings, numbers, booleans and dates', () => {
    expect(nos(filterRows(rows, "type eq 'Job'"))).toEqual(['A', 'B']);
    expect(nos(filterRows(rows, 'hours gt 4'))).toEqual(['A', 'B']);
    expect(nos(filterRows(rows, 'submitted eq true'))).toEqual(['A']);
    expect(nos(filterRows(rows, 'date ge 2026-10-20 and date le 2026-10-25'))).toEqual(['B']);
    expect(nos(filterRows(rows, "type ne 'Job'"))).toEqual(['C']);
  });

  it('handles or, not and brackets with the usual precedence', () => {
    expect(nos(filterRows(rows, "(no eq 'A' or no eq 'C') and hours lt 1"))).toEqual(['C']);
    expect(nos(filterRows(rows, "no eq 'A' or no eq 'C' and hours lt 1"))).toEqual(['A', 'C']);
    expect(nos(filterRows(rows, "not (type eq 'Job')"))).toEqual(['C']);
  });

  it("reads '' inside a string as a quote", () => {
    expect(nos(filterRows(rows, "name eq 'O''Brien'"))).toEqual(['A']);
  });

  it('treats a missing field as not matching (except ne)', () => {
    expect(filterRows(rows, "missing eq 'x'")).toEqual([]);
    expect(filterRows(rows, "missing ne 'x'")).toHaveLength(3);
  });

  it('refuses what it can’t evaluate rather than returning the wrong rows', () => {
    expect(() => filterRows(rows, "contains(name, 'a')")).toThrow(ODataQueryError);
    expect(() => filterRows(rows, "name eq 'open")).toThrow(ODataQueryError);
    expect(() => filterRows(rows, "(no eq 'A'")).toThrow(ODataQueryError);
  });

  it('compares date-time literals as instants', () => {
    const stamped = [
      { no: 'A', at: '2026-10-22T10:00:00.000Z' },
      { no: 'B', at: '2026-10-22T11:30:00.000Z' },
    ];
    expect(nos(filterRows(stamped, 'at ge 2026-10-22T10:00:00Z'))).toEqual(['A', 'B']);
    expect(nos(filterRows(stamped, 'at gt 2026-10-22T11:00:00+01:00'))).toEqual(['B']);
    expect(nos(filterRows(stamped, 'at eq 2026-10-22T10:00:00Z'))).toEqual(['A']);
    expect(filterRows([{ no: 'X', at: 'not a date' }], 'at ge 2026-10-22T10:00:00Z')).toEqual([]);
  });

  it('reads $top strictly', () => {
    const top = (value: string) => queryRows(rows, new URLSearchParams({ $top: value }));
    expect(top('2')).toHaveLength(2);
    expect(top('0')).toHaveLength(0);
    expect(top(String(MAX_TOP))).toHaveLength(3);
    for (const bad of ['', ' ', '0x10', '1e2', '-1', '1.5', String(MAX_TOP + 1), '9'.repeat(400)]) {
      expect(() => top(bad)).toThrow(ODataQueryError);
    }
  });

  it('orders and limits', () => {
    expect(nos(orderRows(rows, 'hours desc'))).toEqual(['A', 'B', 'C']);
    expect(nos(orderRows(rows, 'date asc'))).toEqual(['A', 'B', 'C']);
    const params = new URLSearchParams({ $filter: "type eq 'Job'", $orderby: 'hours', $top: '1' });
    expect(nos(queryRows(rows, params))).toEqual(['B']);
  });
});
