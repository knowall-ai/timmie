import { fromOurFrontDoor } from '@/services/contact/requestGuards';

/**
 * The visitor's IP address for Ask Timmie's rate limits and pass binding.
 *
 * Behind Azure Front Door the right-most X-Forwarded-For entry is Front Door's own
 * address, so it would put every visitor in one bucket. Front Door sets X-Azure-SocketIP
 * (the address that connected to it) and X-Azure-FDID (its profile id), and both can be
 * forged by anyone who reaches the App Service directly. So:
 *
 *  - Front Door configured (FRONT_DOOR_ID, the same setting the enquiry form uses): the
 *    request must carry that X-Azure-FDID, and then X-Azure-SocketIP is the visitor.
 *    Anything else is refused (403): it didn't come through our Front Door. (The enquiry
 *    form is lenient and falls back to X-Forwarded-For; this helper spends money per
 *    request, so it fails closed.)
 *  - Not configured (local development, or no Front Door in front): X-Azure-* headers are
 *    ignored and the address is the one that connected to App Service (or the Next server
 *    locally): the last X-Forwarded-For entry, which App Service appends itself.
 */
export type ClientIpResult = { ok: true; ip: string } | { ok: false; reason: 'front-door' };

function stripPort(value: string): string {
  const v6 = /^\[([^\]]+)\](?::\d+)?$/.exec(value);
  if (v6) return v6[1];
  // IPv4 with a port (one colon); bare IPv6 is left alone.
  return /^[^:]+:\d+$/.test(value) ? value.slice(0, value.lastIndexOf(':')) : value;
}

export function publicClientIp(headers: Headers, frontDoorId: string | undefined): ClientIpResult {
  if (frontDoorId) {
    if (!headers.get('x-azure-fdid')?.trim() || !fromOurFrontDoor(headers, frontDoorId)) {
      return { ok: false, reason: 'front-door' };
    }
    const socket = headers.get('x-azure-socketip')?.trim();
    if (!socket) return { ok: false, reason: 'front-door' };
    return { ok: true, ip: stripPort(socket) };
  }
  const forwarded = headers.get('x-forwarded-for');
  if (forwarded) {
    const last = forwarded.split(',').at(-1)?.trim();
    if (last) return { ok: true, ip: stripPort(last) };
  }
  return { ok: true, ip: headers.get('x-real-ip')?.trim() || 'unknown' };
}
