import type { PublicChatMessage } from '@/services/public-timmie/shared';

/**
 * How the widget sends a text turn and gets a reply. The widget only knows this
 * interface, so another site can plug in its own backend.
 */
export interface ChatTransport {
  /** Sends the conversation so far (visitor and assistant turns, alternating). */
  send(history: PublicChatMessage[]): Promise<{ reply: string; sig?: string; exp?: number }>;
  /**
   * A short summary of the conversation for the enquiry form: of the signed text history,
   * or, given a call key, of the voice call the server recorded.
   */
  summarise(history: PublicChatMessage[], call?: string): Promise<string>;
  /** Forget the conversation (a new one starts with the next message). */
  reset(): void;
}

/**
 * The JSON chat transport for /api/public/chat. Posts the conversation with its id (the
 * server's signatures on earlier replies are bound to it) and the "I am a person" pass in
 * a header; on a 401 (pass expired or its budget spent) it fetches a new pass and retries
 * once.
 */
export function createJsonChatTransport(options: {
  url: string;
  summaryUrl?: string;
  passHeader: string;
  getPass: () => Promise<string>;
  clearPass: () => void;
  fallbackError: string;
}): ChatTransport {
  let conversationId: string | undefined;

  /** POST with the pass; on 401, a fresh pass and one retry. */
  const post = async (url: string, body: unknown) => {
    const attempt = async () =>
      fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          [options.passHeader]: await options.getPass(),
        },
        body: JSON.stringify(body),
      });
    let res = await attempt();
    if (res.status === 401) {
      options.clearPass();
      res = await attempt();
    }
    return res;
  };
  const wire = (history: PublicChatMessage[]) =>
    history.map(({ role, content, sig, exp }) => ({ role, content, sig, exp }));

  return {
    reset() {
      conversationId = undefined;
    },
    async send(history) {
      const res = await post(options.url, { conversationId, messages: wire(history) });
      const body = (await res.json().catch(() => ({}))) as {
        reply?: string;
        sig?: string;
        exp?: number;
        conversationId?: string;
        error?: string;
      };
      if (!res.ok || !body.reply) throw new Error(body.error ?? options.fallbackError);
      conversationId = body.conversationId ?? conversationId;
      return { reply: body.reply, sig: body.sig, exp: body.exp };
    },
    async summarise(history, call) {
      if (!options.summaryUrl) throw new Error(options.fallbackError);
      const res = await post(
        options.summaryUrl,
        call ? { call } : { conversationId, messages: wire(history) }
      );
      const body = (await res.json().catch(() => ({}))) as { summary?: string; error?: string };
      if (!res.ok || !body.summary) throw new Error(body.error ?? options.fallbackError);
      return body.summary;
    },
  };
}
