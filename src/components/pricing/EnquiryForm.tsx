'use client';

import { useEffect, useState, type FormEvent } from 'react';
import { CheckCircleIcon } from '@heroicons/react/24/outline';
import { Button, Input } from '@/components/ui';
import {
  ENQUIRY_OPTIONS,
  ENQUIRY_OPTION_LABELS,
  type EnquiryOption,
} from '@/services/contact/enquiry';
import { ENQUIRY_PREFILL_EVENT, ENQUIRY_PREFILL_KEY } from '@/services/public-timmie/shared';

const MESSAGE_MAX = 5000;

/** A message Ask Timmie left for the form (and clear it, so a later visit starts blank). */
function takePrefill(): string {
  try {
    const text = window.sessionStorage.getItem(ENQUIRY_PREFILL_KEY);
    if (text) window.sessionStorage.removeItem(ENQUIRY_PREFILL_KEY);
    return text ?? '';
  } catch {
    return '';
  }
}

interface EnquiryFormProps {
  option: EnquiryOption;
  onOptionChange: (option: EnquiryOption) => void;
}

type Status = { state: 'idle' | 'sending' | 'sent' } | { state: 'error'; message: string };

export function EnquiryForm({ option, onOptionChange }: EnquiryFormProps) {
  const [status, setStatus] = useState<Status>({ state: 'idle' });
  const [message, setMessage] = useState('');

  // "Send to the team" in Ask Timmie: a summary left in sessionStorage (arriving from
  // another page) or raised as an event (the widget on this page) fills the message box.
  useEffect(() => {
    const take = (text: string) => text && setMessage(text.slice(0, MESSAGE_MAX));
    take(takePrefill());
    const onPrefill = (e: Event) => take(String((e as CustomEvent<string>).detail ?? ''));
    window.addEventListener(ENQUIRY_PREFILL_EVENT, onPrefill);
    return () => window.removeEventListener(ENQUIRY_PREFILL_EVENT, onPrefill);
  }, []);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    setStatus({ state: 'sending' });
    try {
      const res = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...Object.fromEntries(form), option }),
      });
      if (res.ok) {
        setStatus({ state: 'sent' });
        return;
      }
      const body = (await res.json().catch(() => ({}))) as { error?: string };
      setStatus({
        state: 'error',
        message: body.error ?? 'Could not send your message. Please email hello@knowall.ai.',
      });
    } catch {
      setStatus({
        state: 'error',
        message: 'Could not send your message. Please email hello@knowall.ai.',
      });
    }
  };

  if (status.state === 'sent') {
    return (
      <div className="flex flex-col items-center py-10 text-center" role="status">
        <CheckCircleIcon className="text-brand mb-4 h-12 w-12" />
        <h3 className="mb-2 text-xl font-semibold text-white">Thanks, we&apos;ve got it</h3>
        <p className="text-dark-300 max-w-md">
          We&apos;ll reply to the email address you gave, usually within one working day.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5" data-testid="enquiry-form">
      <fieldset>
        <legend className="text-dark-200 mb-2 block text-sm font-medium">
          What are you interested in?
        </legend>
        <div className="flex flex-wrap gap-2">
          {ENQUIRY_OPTIONS.map((o) => (
            <label key={o} className="cursor-pointer">
              <input
                type="radio"
                name="option-choice"
                value={o}
                checked={option === o}
                onChange={() => onOptionChange(o)}
                className="peer sr-only"
              />
              <span className="border-dark-600 bg-dark-800 text-dark-300 peer-checked:border-brand peer-checked:bg-brand/10 peer-checked:text-brand peer-focus-visible:ring-brand hover:border-dark-500 inline-block rounded-full border px-4 py-2 text-sm font-medium transition-colors peer-focus-visible:ring-2">
                {ENQUIRY_OPTION_LABELS[o]}
              </span>
            </label>
          ))}
        </div>
      </fieldset>

      <div className="grid gap-5 sm:grid-cols-2">
        <Input
          label="Name"
          id="enquiry-name"
          name="name"
          required
          minLength={2}
          maxLength={100}
          autoComplete="name"
        />
        <Input
          label="Work email"
          id="enquiry-email"
          name="email"
          type="email"
          required
          maxLength={200}
          autoComplete="email"
        />
        <Input
          label="Company (optional)"
          id="enquiry-company"
          name="company"
          maxLength={120}
          autoComplete="organization"
        />
        <Input
          label="How many people? (optional)"
          id="enquiry-users"
          name="users"
          maxLength={20}
          inputMode="numeric"
          placeholder="e.g. 12"
        />
      </div>

      <div>
        <label htmlFor="enquiry-message" className="text-dark-200 mb-1 block text-sm font-medium">
          Message
        </label>
        <textarea
          id="enquiry-message"
          name="message"
          required
          minLength={10}
          maxLength={MESSAGE_MAX}
          rows={5}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder="Tell us about your team and how you use Business Central."
          className="border-dark-600 bg-dark-800 placeholder:text-dark-400 focus:ring-brand w-full rounded-lg border px-3 py-2 text-sm text-white focus:border-transparent focus:ring-2 focus:outline-none"
        />
      </div>

      {/* Honeypot: hidden from people and screen readers, filled in by naive bots */}
      <div className="hidden" aria-hidden="true">
        <label>
          Website
          <input type="text" name="website" tabIndex={-1} autoComplete="off" />
        </label>
      </div>

      {status.state === 'error' && (
        <p className="text-sm text-red-400" role="alert">
          {status.message}
        </p>
      )}

      <div className="flex flex-wrap items-center gap-4">
        <Button type="submit" size="lg" disabled={status.state === 'sending'}>
          {status.state === 'sending' ? 'Sending...' : 'Send enquiry'}
        </Button>
        <p className="text-dark-500 text-sm">
          Or email{' '}
          <a href="mailto:hello@knowall.ai" className="text-brand hover:underline">
            hello@knowall.ai
          </a>
        </p>
      </div>
    </form>
  );
}
