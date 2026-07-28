import { spawnSync } from "node:child_process";
import {
  CustomEditor,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

const ENABLE_FOCUS_REPORTING = "\x1b[?1004h";
const DISABLE_FOCUS_REPORTING = "\x1b[?1004l";
const FOCUS_IN = "\x1b[I";
const FOCUS_OUT = "\x1b[O";
const SOFTWARE_CURSOR = /\x1b\[7m(.*?)\x1b\[(?:0|27)m/g;

interface PaneFocusState {
  focused: boolean;
  requestRender?: () => void;
}

function getInitialFocus(): boolean {
  const pane = process.env.TMUX_PANE;
  if (!pane) return true;

  const result = spawnSync(
    "tmux",
    [
      "display-message",
      "-p",
      "-t",
      pane,
      "#{?#{&&:#{pane_active},#{window_active}},1,0}",
    ],
    { encoding: "utf8" },
  );
  return result.status === 0 ? result.stdout.trim() === "1" : true;
}

function applyFocusEvent(data: string, state: PaneFocusState): boolean {
  const focusInIndex = data.lastIndexOf(FOCUS_IN);
  const focusOutIndex = data.lastIndexOf(FOCUS_OUT);
  if (focusInIndex === -1 && focusOutIndex === -1) return false;

  const focused = focusInIndex > focusOutIndex;
  if (state.focused !== focused) {
    state.focused = focused;
    state.requestRender?.();
  }
  return true;
}

class PaneFocusEditor extends CustomEditor {
  constructor(
    tui: ConstructorParameters<typeof CustomEditor>[0],
    theme: ConstructorParameters<typeof CustomEditor>[1],
    keybindings: ConstructorParameters<typeof CustomEditor>[2],
    private readonly paneFocus: PaneFocusState,
  ) {
    super(tui, theme, keybindings);
    this.paneFocus.requestRender = () => tui.requestRender();
  }

  handleInput(data: string): void {
    if (applyFocusEvent(data, this.paneFocus)) return;
    super.handleInput(data);
  }

  render(width: number): string[] {
    if (this.paneFocus.focused) return super.render(width);

    // Prevent the IME hardware-cursor marker as well as removing Pi's
    // reverse-video software cursor from the rendered editor text.
    const componentFocused = this.focused;
    this.focused = false;
    try {
      return super
        .render(width)
        .map((line) => line.replace(SOFTWARE_CURSOR, "$1"));
    } finally {
      this.focused = componentFocused;
    }
  }
}

export default function (pi: ExtensionAPI) {
  const paneFocus: PaneFocusState = { focused: true };
  let focusReportingEnabled = false;
  let inputRemainder = "";

  const handleRawInput = (chunk: string | Buffer): void => {
    const data = inputRemainder + chunk.toString();
    applyFocusEvent(data, paneFocus);
    inputRemainder = data.slice(-(FOCUS_IN.length - 1));
  };

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui" || focusReportingEnabled) return;

    paneFocus.focused = getInitialFocus();
    ctx.ui.setEditorComponent(
      (tui, theme, keybindings) =>
        new PaneFocusEditor(tui, theme, keybindings, paneFocus),
    );

    focusReportingEnabled = true;
    process.stdin.on("data", handleRawInput);
    process.stdout.write(ENABLE_FOCUS_REPORTING);
  });

  pi.on("session_shutdown", () => {
    if (!focusReportingEnabled) return;

    process.stdin.removeListener("data", handleRawInput);
    process.stdout.write(DISABLE_FOCUS_REPORTING);
    paneFocus.requestRender = undefined;
    inputRemainder = "";
    focusReportingEnabled = false;
  });
}
