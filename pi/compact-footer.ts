import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

function formatTokens(count: number): string {
    if (count < 1_000) return `${count}`;
    if (count < 10_000) return `${(count / 1_000).toFixed(1)}k`;
    if (count < 1_000_000) return `${Math.round(count / 1_000)}k`;
    if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
    return `${Math.round(count / 1_000_000)}M`;
}

export default function (pi: ExtensionAPI) {
    pi.on("session_start", async (_event, ctx) => {
        if (ctx.mode !== "tui") return;

        ctx.ui.setFooter((tui, theme, footerData) => {
            const unsubscribe = footerData.onBranchChange(() => tui.requestRender());

            return {
                dispose: unsubscribe,
                invalidate() {},

                render(width: number): string[] {
                    let totalTokens = 0;

                    for (const entry of ctx.sessionManager.getEntries()) {
                        let usage;

                        if (entry.type === "message" && entry.message.role === "assistant") {
                            usage = entry.message.usage;
                        } else if (
                            entry.type === "message" &&
                            entry.message.role === "toolResult" &&
                            entry.message.usage
                        ) {
                            usage = entry.message.usage;
                        } else if (
                            (entry.type === "branch_summary" || entry.type === "compaction") &&
                            entry.usage
                        ) {
                            usage = entry.usage;
                        }

                        if (usage) {
                            totalTokens +=
                                usage.input +
                                usage.output +
                                usage.cacheRead +
                                usage.cacheWrite;
                        }
                    }

                    const branch = footerData.getGitBranch();
                    const cwd = ctx.sessionManager.getCwd();
                    const location = branch ? `${cwd} (${branch})` : cwd;

                    const context = ctx.getContextUsage();
                    const contextWindow = context?.contextWindow ?? 0;
                    const contextPercent =
                        context?.percent == null ? "?" : context.percent.toFixed(1);

                    const stats =
                        `T${formatTokens(totalTokens)} ` +
                        `${contextPercent}%/${formatTokens(contextWindow)}`;

                    return [
                        truncateToWidth(theme.fg("dim", location), width),
                        theme.fg("dim", stats),
                    ];
                },
            };
        });
    });
}
