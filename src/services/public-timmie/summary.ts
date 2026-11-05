/**
 * The hand-off from Ask Timmie to the enquiry form: a short, editable summary of what the
 * visitor wants, written on the server from the conversation, that the widget drops into
 * the form's message box. The visitor adds their own name and email there, never here.
 *
 * Whatever the model writes is cleaned before it leaves the server: links, markdown and
 * HTML removed, email addresses and phone numbers scrubbed, and the whole thing capped.
 */
export const SUMMARY_MAX_CHARS = 600;

export interface SummaryTurn {
  role: 'user' | 'assistant';
  content: string;
}

export type SummarySource = 'chat' | 'voice';

export const SUMMARY_INSTRUCTIONS = `You draft the message box of an enquiry form on Timmie's website, from a conversation a visitor has just had with Timmie, the public helper. (Timmie is time tracking for Microsoft Dynamics 365 Business Central, made by KnowAll AI.)
Write two to four short sentences in the first person, as the visitor, saying what they want from the team: their situation as far as the conversation says it (whether they use Business Central, roughly how many people log time, how they track time today, what is painful) and what they are asking for (a demo, hosting, support, a pricing question). Use only what the conversation says; invent nothing, and leave out anything it doesn't cover rather than guessing.
Never include a person's name, email address, phone number, job title, company or organisation name, address, or anything else that identifies a person or an organisation, even if the visitor gave it: leave it out.
Plain text only: no greeting, no sign-off, no markdown, no links, no quotation marks around the whole thing. British English.`;

/** The conversation as one block of text for the summariser. */
export function summaryTranscript(turns: SummaryTurn[], source: SummarySource): string {
  const lines = turns.map((t) => `${t.role === 'user' ? 'Visitor' : 'Timmie'}: ${t.content}`);
  const note =
    source === 'voice'
      ? "This was a voice call. Only Timmie's side was recorded; the visitor's words are not available, so infer what they asked only from Timmie's replies, and keep it general.\n\n"
      : '';
  return `${note}${lines.join('\n\n')}`;
}

const MARKDOWN_LINK = /\[([^\]]*)\]\([^)]*\)/g;
const HTML = /<\/?[a-z][^>]*>/gi;
const URL = /\b(?:https?:\/\/|www\.)\S+/gi;
const EMAIL = /[\w.+-]+@[\w-]+(?:\.[\w-]+)+/g;
/** Runs of digits with separators; only those with seven or more digits are removed. */
const PHONE_CANDIDATE = /\+?[\d\s().-]{8,}/g;

export function cleanSummary(text: string): string {
  let out = text
    .replace(MARKDOWN_LINK, '$1')
    .replace(HTML, '')
    .replace(URL, '')
    .replace(EMAIL, '')
    .replace(PHONE_CANDIDATE, (m) => (m.replace(/\D/g, '').length >= 7 ? ' ' : m))
    .replace(/[*_`#>]/g, '')
    .replace(/^["'\s]+|["'\s]+$/g, '')
    .replace(/[ \t]+/g, ' ')
    .replace(/ ?\n ?/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/ ([.,;:!?])/g, '$1')
    .trim();
  if (out.length > SUMMARY_MAX_CHARS) {
    out = out.slice(0, SUMMARY_MAX_CHARS);
    const end = Math.max(out.lastIndexOf('. '), out.lastIndexOf('.\n'));
    out = (end > SUMMARY_MAX_CHARS / 2 ? out.slice(0, end + 1) : out).trimEnd();
  }
  return out;
}

/**
 * Without the model (switched off, unconfigured, or failing): an opening line plus the
 * visitor's own first question, cleaned the same way. Always something usable.
 */
export function fallbackSummary(turns: SummaryTurn[], source: SummarySource): string {
  const intro =
    source === 'voice'
      ? "I've just been talking to Timmie on your website and would like to hear from the team about Timmie."
      : "I've been chatting with Timmie on your website and would like to hear from the team about Timmie.";
  const first = turns.find((t) => t.role === 'user')?.content.trim();
  if (!first) return intro;
  return cleanSummary(`${intro} My question was: ${first.slice(0, 200)}`);
}
