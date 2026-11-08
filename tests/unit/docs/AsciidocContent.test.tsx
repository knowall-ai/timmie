import { readFileSync } from 'fs';
import path from 'path';
import Asciidoctor from 'asciidoctor';
import { render, screen, waitFor } from '@testing-library/react';
import { describe, it, expect, beforeAll, afterEach, vi } from 'vitest';
import { AsciidocContent, tablesToDisclosures } from '@/components/docs/AsciidocContent';

// Under jsdom the Node build of asciidoctor tries to turn the page's http:// address into a file
// path and fails to load. Use the browser build, which is the one webpack ships to users anyway.
// (A relative path, because the package's exports map hides it; it has no type declarations.)
vi.mock(
  'asciidoctor',
  // @ts-expect-error untyped deep import of the browser build
  () => import('../../../node_modules/@asciidoctor/core/dist/browser/asciidoctor.js')
);

const asciidoctor = Asciidoctor();

function toHtml(adoc: string): string {
  return asciidoctor.convert(adoc, { standalone: false, safe: 'safe' }) as string;
}

function parse(html: string): Document {
  return new DOMParser().parseFromString(html, 'text/html');
}

const troubleshootingAdoc = readFileSync(
  path.join(process.cwd(), 'docs', 'TROUBLESHOOTING.adoc'),
  'utf-8'
);

// Count the rows in the source without asciidoctor: inside each |=== block every
// row is two lines starting "| " (problem, then solution), after a one-line header
function countSourceRows(adoc: string): number {
  let inTable = false;
  let cellLines = 0;
  let headers = 0;
  for (const line of adoc.split('\n')) {
    if (line.startsWith('|===')) {
      inTable = !inTable;
      continue;
    }
    if (!inTable || !line.startsWith('| ')) continue;
    if (line.startsWith('| Problem | Solution')) headers++;
    else cellLines++;
  }
  expect(headers).toBeGreaterThan(0);
  expect(cellLines % 2).toBe(0);
  return cellLines / 2;
}

describe('tablesToDisclosures', () => {
  it('turns every row of the real troubleshooting guide into a question, and leaves no table', () => {
    const doc = parse(tablesToDisclosures(toHtml(troubleshootingAdoc)));
    const details = doc.querySelectorAll('details');

    expect(details.length).toBe(countSourceRows(troubleshootingAdoc));
    expect(doc.querySelectorAll('table').length).toBe(0);

    // The header row is not a question, and every question has a title and an answer
    details.forEach((d) => {
      const title = d.querySelector('summary')?.textContent?.trim();
      expect(title).toBeTruthy();
      expect(title).not.toBe('Problem');
      expect(d.querySelector('div')?.textContent?.trim()).toBeTruthy();
    });

    // Every id is unique
    const ids = Array.from(details).map((d) => d.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids.every((id) => /^[a-z0-9-]+$/.test(id))).toBe(true);
  });

  it('keeps the section headings between the tables', () => {
    const doc = parse(tablesToDisclosures(toHtml(troubleshootingAdoc)));
    const headings = Array.from(doc.querySelectorAll('h2')).map((h) => h.textContent);
    expect(headings).toContain('Signing in and access');
    expect(headings).toContain('Developers and self-hosting');
  });

  it('gives each question an id from its title, with a number on repeats', () => {
    const html = tablesToDisclosures(
      toHtml(`|===
| Problem | Solution

| Timer state lost on refresh
| First answer

| Timer state lost on refresh
| Second answer

| ???
| No letters in this title
|===`)
    );
    const ids = Array.from(parse(html).querySelectorAll('details')).map((d) => d.id);
    expect(ids).toEqual([
      'timer-state-lost-on-refresh',
      'timer-state-lost-on-refresh-2',
      'question',
    ]);
  });

  it('keeps links, inline code and bold text in the question and the answer', () => {
    const doc = parse(
      tablesToDisclosures(
        toHtml(`|===
| Problem | Solution

| Build fails with \`bun run build\`
| See https://github.com/knowall-ai/timmie/issues[the issues] and run *bun install* first.
|===`)
      )
    );
    const details = doc.querySelector('details');
    expect(details?.querySelector('summary code')?.textContent).toBe('bun run build');
    expect(details?.querySelector('summary svg')?.getAttribute('aria-hidden')).toBe('true');

    const answer = details?.querySelector('div');
    expect(answer?.querySelector('a')?.getAttribute('href')).toBe(
      'https://github.com/knowall-ai/timmie/issues'
    );
    expect(answer?.querySelector('a')?.textContent).toBe('the issues');
    expect(answer?.querySelector('strong')?.textContent).toBe('bun install');
  });

  it('leaves a table alone unless every row has exactly two cells', () => {
    const threeColumns = tablesToDisclosures(
      toHtml(`|===
| Name | Type | Default

| port
| number
| 3101
|===`)
    );
    expect(parse(threeColumns).querySelectorAll('details').length).toBe(0);
    expect(parse(threeColumns).querySelectorAll('table tbody td').length).toBe(3);

    // A header-style column renders as <th>, so a "h,1,1" table has two <td> per row
    // but is still three columns: it stays a table and keeps the <th> content
    const headerColumn = tablesToDisclosures(
      toHtml(`[cols="h,1,1"]
|===
| port
| number
| 3101
|===`)
    );
    expect(parse(headerColumn).querySelectorAll('details').length).toBe(0);
    expect(parse(headerColumn).querySelector('table tbody th')?.textContent).toBe('port');

    const oneColumn = tablesToDisclosures(toHtml('|===\n| Only cell\n|==='));
    expect(parse(oneColumn).querySelectorAll('details').length).toBe(0);
    expect(parse(oneColumn).querySelector('table')).not.toBeNull();

    // A two-column table in the same document is still converted
    const mixed = tablesToDisclosures(
      toHtml(`|===
| a | b | c
|===

|===
| Problem | Solution

| Question
| Answer
|===`)
    );
    expect(parse(mixed).querySelectorAll('table').length).toBe(1);
    expect(parse(mixed).querySelectorAll('details').length).toBe(1);
  });

  it('keeps a table nested in an answer, and does not count its rows as questions', () => {
    const doc = parse(
      tablesToDisclosures(
        toHtml(`|===
| Problem | Solution

| Which port?
a| It depends:
!===
! Script ! Port

! dev ! 3101
! start ! 3000
!===
|===`)
      )
    );
    const details = doc.querySelectorAll('details');
    expect(details.length).toBe(1);
    expect(details[0].querySelector('summary')?.textContent?.trim()).toBe('Which port?');

    const nested = details[0].querySelector('div table');
    expect(nested).not.toBeNull();
    expect(nested?.querySelectorAll('tbody tr').length).toBe(2);
    expect(doc.querySelectorAll('table').length).toBe(1);
  });

  it('leaves text and lists outside the tables alone', () => {
    const html = tablesToDisclosures(toHtml('Intro paragraph.\n\n* one\n* two'));
    const doc = parse(html);
    expect(doc.querySelector('p')?.textContent).toBe('Intro paragraph.');
    expect(doc.querySelectorAll('li').length).toBe(2);
    expect(doc.querySelectorAll('details').length).toBe(0);
  });
});

describe('AsciidocContent with collapsibleTables', () => {
  const adoc = `|===
| Problem | Solution

| First question
| First answer

| Second question
| Second answer
|===`;

  beforeAll(() => {
    // jsdom has no layout, so it doesn't implement scrollIntoView
    Element.prototype.scrollIntoView = vi.fn();
  });

  afterEach(() => {
    window.location.hash = '';
    vi.clearAllMocks();
  });

  it('renders the rows as closed questions', async () => {
    render(<AsciidocContent content={adoc} collapsibleTables />);
    const first = await screen.findByText('First question');
    const details = first.closest('details');
    expect(details).not.toBeNull();
    expect(details?.open).toBe(false);
    expect(details?.querySelector('summary')).not.toBeNull();
  });

  it('opens and scrolls to the question named in the address', async () => {
    window.location.hash = '#second-question';
    render(<AsciidocContent content={adoc} collapsibleTables />);
    const second = await screen.findByText('Second question');
    const details = second.closest('details') as HTMLDetailsElement;
    await waitFor(() => expect(details.open).toBe(true));
    expect(Element.prototype.scrollIntoView).toHaveBeenCalledWith({ block: 'start' });
    expect((screen.getByText('First question').closest('details') as HTMLDetailsElement).open).toBe(
      false
    );
  });

  it('opens a question when the hash changes after the page has loaded', async () => {
    render(<AsciidocContent content={adoc} collapsibleTables />);
    const first = (await screen.findByText('First question')).closest(
      'details'
    ) as HTMLDetailsElement;
    expect(first.open).toBe(false);

    window.location.hash = '#first-question';
    window.dispatchEvent(new HashChangeEvent('hashchange'));
    await waitFor(() => expect(first.open).toBe(true));
  });

  it('ignores a hash that is not a valid encoding', async () => {
    window.location.hash = '#%E0%A4%A';
    render(<AsciidocContent content={adoc} collapsibleTables />);
    await screen.findByText('First question');
    expect(Element.prototype.scrollIntoView).not.toHaveBeenCalled();
  });

  it('keeps tables as tables when collapsibleTables is off', async () => {
    const { container } = render(<AsciidocContent content={adoc} />);
    await screen.findByText('First question');
    expect(container.querySelector('table')).not.toBeNull();
    expect(container.querySelector('details')).toBeNull();
  });
});
