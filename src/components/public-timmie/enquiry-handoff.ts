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
  try {
    browserStore('session')?.setItem(ENQUIRY_PREFILL_KEY, summary);
  } catch {
    // Storage blocked: the event below still reaches a form on this page.
  }
  window.dispatchEvent(new CustomEvent<string>(ENQUIRY_PREFILL_EVENT, { detail: summary }));
  const [path, hash] = ENQUIRY_PATH.split('#');
  if (window.location.pathname === path) {
    window.location.hash = hash;
    document.getElementById(hash)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  } else {
    window.location.assign(ENQUIRY_PATH);
  }
}
