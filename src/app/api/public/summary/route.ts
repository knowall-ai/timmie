import { publicSummary } from '@/services/public-timmie/azure';
import { publicAiDisabled, publicAzureConfig } from '@/services/public-timmie/config';
import { globalLimit, guard, jsonError, logEvent, readJson } from '@/services/public-timmie/guard';
import { findCall } from '@/services/public-timmie/live-calls';
import { modelTurns, parseChat } from '@/services/public-timmie/messages';
import { verifyChain } from '@/services/public-timmie/pass';
import { limiters } from '@/services/public-timmie/rate-limit';
import {
  cleanSummary,
  fallbackSummary,
  type SummarySource,
  type SummaryTurn,
} from '@/services/public-timmie/summary';

export const dynamic = 'force-dynamic';

/**
 * "Send to the team": a short, editable summary of the conversation for the enquiry form's
 * message box. Same guards as chat (pass, per-IP and global limits), and the same signed
 * history: a text conversation must verify as a chain, and a voice call is summarised from
 * the replies the server itself recorded (`{ call }`, the call key, from the same IP). The
 * visitor's own name and email are never involved: the form asks for those.
 */
export async function POST(request: Request) {
  const checked = guard(request, { pass: 'chat', limits: [limiters.chat] });
  if (!checked.ok) return checked.response;
  const body = (await readJson(request, 64 * 1024)) as { call?: unknown } | undefined;

  let turns: SummaryTurn[];
  let source: SummarySource;
  if (body && typeof body === 'object' && 'call' in body) {
    const call = findCall(body.call, checked.ip);
    if (!call) return jsonError(404, 'No such call.');
    turns = call.replies.map((content) => ({ role: 'assistant', content }));
    source = 'voice';
  } else {
    const chat = parseChat(body);
    if (!chat || (!chat.conversationId && chat.messages.length > 1)) {
      return jsonError(400, 'Invalid request.');
    }
    const chain = verifyChain(chat.conversationId ?? '', chat.messages);
    if (!chain.ok) {
      logEvent({ kind: 'summary', ok: false, chain: chain.reason });
      return jsonError(409, 'This conversation can’t be continued. Please start a new one.');
    }
    turns = modelTurns(chat.messages);
    source = 'chat';
  }

  const respond = (summary: string, how: string) => {
    logEvent({
      kind: 'summary',
      ok: true,
      source,
      how,
      turns: turns.length,
      chars: summary.length,
    });
    return Response.json({ summary }, { headers: { 'Cache-Control': 'no-store' } });
  };
  const config = publicAzureConfig();
  // A call that ended before Timmie finished a reply has nothing for the model: the fallback.
  if (turns.length === 0 || publicAiDisabled() || !config?.chatDeployment) {
    return respond(fallbackSummary(turns, source), 'fallback');
  }
  const busy = globalLimit(limiters.chatGlobal);
  if (busy) return busy;
  try {
    const summary = cleanSummary(await publicSummary(config, turns, source));
    return summary ? respond(summary, 'model') : respond(fallbackSummary(turns, source), 'empty');
  } catch {
    // The form still works with the fallback; nothing the visitor needs to see.
    return respond(fallbackSummary(turns, source), 'error');
  }
}
