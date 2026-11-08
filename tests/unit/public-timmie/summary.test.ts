import { describe, expect, it } from 'vitest';
import { publicSummaryRequest } from '@/services/public-timmie/azure';
import {
  SUMMARY_INSTRUCTIONS,
  SUMMARY_MAX_CHARS,
  cleanSummary,
  fallbackSummary,
  summaryTranscript,
} from '@/services/public-timmie/summary';

describe('the enquiry-form summary', () => {
  it('scrubs email addresses, phone numbers, links, markdown and HTML', () => {
    const dirty =
      "I'm **Bob Smith** (bob.smith+work@example.co.uk, +44 7700 900123). We have 12 people on [Business Central](https://example.com/bc) and want a demo: see https://evil.example/x <script>alert(1)</script>. Budget code 2024-11.";
    const clean = cleanSummary(dirty);
    expect(clean).not.toMatch(/@/);
    expect(clean).not.toMatch(/7700|900123/);
    expect(clean).not.toMatch(/https?:|example\.com|evil/);
    expect(clean).not.toMatch(/[*<>\[\]]/);
    expect(clean).toContain('12 people');
    expect(clean).toContain('Business Central');
    expect(clean).toContain('2024-11');
  });

  it('caps the length at a sentence end', () => {
    const long = 'We log time for twenty people in Business Central. '.repeat(40);
    const clean = cleanSummary(long);
    expect(clean.length).toBeLessThanOrEqual(SUMMARY_MAX_CHARS);
    expect(clean.endsWith('.')).toBe(true);
    expect(cleanSummary('x'.repeat(2000)).length).toBe(SUMMARY_MAX_CHARS);
  });

  it('tidies whitespace and surrounding quotes', () => {
    expect(cleanSummary('  "We  want\n\n\n a   demo ."  ')).toBe('We want\n\na demo.');
  });

  it('the fallback is usable, in the visitor’s words, and cleaned the same way', () => {
    expect(fallbackSummary([], 'chat')).toMatch(/hear from the team/);
    expect(fallbackSummary([], 'voice')).toMatch(/talking to Timmie/);
    const withQuestion = fallbackSummary(
      [
        { role: 'user', content: 'Can 15 of us use it? Email me: jo@example.org' },
        { role: 'assistant', content: 'Yes.' },
      ],
      'chat'
    );
    expect(withQuestion).toContain('My question was: Can 15 of us use it?');
    expect(withQuestion).not.toMatch(/@/);
  });

  it('asks the model for a first-person draft with no identifying details', () => {
    expect(SUMMARY_INSTRUCTIONS).toMatch(/two to four short sentences in the first person/);
    expect(SUMMARY_INSTRUCTIONS).toMatch(
      /Never include a person's name, email address, phone number/
    );
    expect(SUMMARY_INSTRUCTIONS).toMatch(/invent nothing/);
    const request = publicSummaryRequest(
      'chat-model',
      [
        { role: 'user', content: 'Hi' },
        { role: 'assistant', content: 'Hello' },
      ],
      'chat'
    );
    expect(request).toMatchObject({ tools: [], tool_choice: 'none', store: false });
    expect(request.input).toEqual([{ role: 'user', content: 'Visitor: Hi\n\nTimmie: Hello' }]);
    expect(summaryTranscript([{ role: 'assistant', content: 'Hello' }], 'voice')).toMatch(
      /voice call[\s\S]*Timmie: Hello/
    );
  });
});
