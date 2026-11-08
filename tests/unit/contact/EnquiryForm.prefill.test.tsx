import { act, render, screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { EnquiryForm } from '@/components/pricing/EnquiryForm';
import { ENQUIRY_PREFILL_EVENT, ENQUIRY_PREFILL_KEY } from '@/services/public-timmie/shared';

/** A real key-value store (the test setup replaces storage with no-op mocks). */
function memoryStorage(): Storage {
  const data = new Map<string, string>();
  return {
    get length() {
      return data.size;
    },
    clear: () => data.clear(),
    getItem: (k) => data.get(k) ?? null,
    key: (i) => [...data.keys()][i] ?? null,
    removeItem: (k) => void data.delete(k),
    setItem: (k, v) => void data.set(k, String(v)),
  };
}

describe('the enquiry form takes a summary from Ask Timmie', () => {
  let session: Storage;
  beforeEach(() => {
    session = memoryStorage();
    vi.spyOn(window, 'sessionStorage', 'get').mockReturnValue(session);
  });
  afterEach(() => {
    vi.restoreAllMocks();
  });

  const message = () => screen.getByLabelText('Message') as HTMLTextAreaElement;

  it('fills the message box from sessionStorage once, then clears it', () => {
    session.setItem(ENQUIRY_PREFILL_KEY, 'We have 12 people on Business Central and want a demo.');
    render(<EnquiryForm option="hosting" onOptionChange={() => undefined} />);
    expect(message().value).toBe('We have 12 people on Business Central and want a demo.');
    expect(session.getItem(ENQUIRY_PREFILL_KEY)).toBeNull();
  });

  it('starts blank without one, and takes the event when the widget is on the same page', () => {
    render(<EnquiryForm option="support" onOptionChange={() => undefined} />);
    expect(message().value).toBe('');
    act(() => {
      window.dispatchEvent(
        new CustomEvent(ENQUIRY_PREFILL_EVENT, { detail: 'Summary from the same page.' })
      );
    });
    expect(message().value).toBe('Summary from the same page.');
  });

  it('stays editable', () => {
    session.setItem(ENQUIRY_PREFILL_KEY, 'Draft.');
    render(<EnquiryForm option="hosting" onOptionChange={() => undefined} />);
    act(() => {
      const el = message();
      const setter = Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value')!.set!;
      setter.call(el, 'Draft, edited by me.');
      el.dispatchEvent(new Event('input', { bubbles: true }));
    });
    expect(message().value).toBe('Draft, edited by me.');
  });
});
