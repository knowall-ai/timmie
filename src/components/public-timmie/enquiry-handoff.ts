'use client';

import {
  ENQUIRY_PATH,
  ENQUIRY_PREFILL_EVENT,
  ENQUIRY_PREFILL_KEY,
} from '@/services/public-timmie/shared';
import { browserStore } from './storage';

/**
 * Hands a summary to the enquiry form on the pricing page: stored for the form to read
 * when it mounts (another page), or raised as an event when the form is already on this
 * page. The visitor checks and edits it there, adds their own name and email, and sends.
 */
export function handOffToEnquiryForm(summary: string) {
  const [path, hash] = ENQUIRY_PATH.split('#');
  if (window.location.pathname === path) {
    // The form is on this page: the event alone, so nothing is left in storage for later.
    window.dispatchEvent(new CustomEvent<string>(ENQUIRY_PREFILL_EVENT, { detail: summary }));
    window.location.hash = hash;
    document.getElementById(hash)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    return;
  }
  try {
    browserStore('session')?.setItem(ENQUIRY_PREFILL_KEY, summary);
  } catch {
    // Storage blocked: the form opens blank, which still works.
  }
  window.location.assign(ENQUIRY_PATH);
}
