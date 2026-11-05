import { authHeaders } from './auth';
import type { PublicAzureConfig } from './config';
import { publicTimmieInstructions } from './prompt';
import {
  SUMMARY_INSTRUCTIONS,
  summaryTranscript,
  type SummarySource,
  type SummaryTurn,
} from './summary';

/**
 * Ask Timmie's text chat, on Timmie's own Azure OpenAI resource (the Responses API on the
 * v1 surface). No tools are ever sent (`tools: []`, `tool_choice: 'none'`) and nothing is
 * stored (`store: false`). Voice is in live.ts.
 */
export interface ChatTurn {
  role: 'user' | 'assistant';
  content: string;
}

export class UpstreamError extends Error {
  constructor(
    readonly status: number,
    readonly code?: string
  ) {
    super(`Azure OpenAI ${status}${code ? ` ${code}` : ''}`);
  }
}

/** The body of one stateless text turn. Exported for tests. */
export function publicChatRequest(deployment: string, turns: ChatTurn[]) {
  return {
    model: deployment,
    instructions: publicTimmieInstructions('chat'),
    input: turns.map((t) => ({ role: t.role, content: t.content })),
    tools: [],
    tool_choice: 'none',
    store: false,
    reasoning: { effort: 'low' },
    max_output_tokens: 1200,
  };
}

/**
 * The body of a summary request for the enquiry form: the conversation goes in as one
 * visitor message, so the model summarises it rather than carrying it on. Exported for tests.
 */
export function publicSummaryRequest(
  deployment: string,
  turns: SummaryTurn[],
  source: SummarySource
) {
  return {
    model: deployment,
    instructions: SUMMARY_INSTRUCTIONS,
    input: [{ role: 'user', content: summaryTranscript(turns, source) }],
    tools: [],
    tool_choice: 'none',
    store: false,
    reasoning: { effort: 'low' },
    max_output_tokens: 400,
  };
}

/** One call to the Responses API on the public resource; the reply's text. */
async function responses(config: PublicAzureConfig, body: unknown): Promise<string> {
  const response = await fetch(`${config.endpoint}/openai/v1/responses`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(await authHeaders(config.apiKey)) },
    body: JSON.stringify(body),
    cache: 'no-store',
    signal: AbortSignal.timeout(45_000),
  });
  const result = (await response.json().catch(() => ({}))) as {
    output?: { type?: string; content?: { type: string; text?: string }[] }[];
    error?: { code?: string };
  };
  if (!response.ok || !result.output) throw new UpstreamError(response.status, result.error?.code);
  let text = '';
  for (const item of result.output) {
    if (item.type !== 'message') continue;
    for (const part of item.content ?? []) {
      if (part.type === 'output_text' && part.text) text += part.text;
    }
  }
  return text;
}

/** One stateless text turn: `store: false`, no tools. */
export async function publicChat(config: PublicAzureConfig, turns: ChatTurn[]): Promise<string> {
  if (!config.chatDeployment) throw new UpstreamError(503, 'not_configured');
  return responses(config, publicChatRequest(config.chatDeployment, turns));
}

/** A short summary of the conversation for the enquiry form (cleaned by the caller). */
export async function publicSummary(
  config: PublicAzureConfig,
  turns: SummaryTurn[],
  source: SummarySource
): Promise<string> {
  if (!config.chatDeployment) throw new UpstreamError(503, 'not_configured');
  return responses(config, publicSummaryRequest(config.chatDeployment, turns, source));
}
