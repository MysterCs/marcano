from __future__ import annotations

import os
import queue
import sys
import tkinter as tk
import webbrowser
from pathlib import Path
from tkinter import scrolledtext, ttk

from .process_manager import AppProcessManager, AppState

POLL_INTERVAL_MS = 150


class MarcanoControl(tk.Tk):
    """Panel local para iniciar, pausar, reanudar y detener Marcano."""

    def __init__(self, project_root: Path) -> None:
        super().__init__()
        self.project_root = project_root
        self.title("Marcano Control")
        self.geometry("960x640")
        self.minsize(720, 420)
        self.protocol("WM_DELETE_WINDOW", self._on_close)

        style = ttk.Style(self)
        try:
            style.theme_use("vista")
        except tk.TclError:
            pass

        self.log_queue: queue.Queue[str] = queue.Queue()
        self.manager = AppProcessManager(project_root, self._enqueue_log)

        self.info_var = tk.StringVar(value="")
        self.action_text_var = tk.StringVar(value="Iniciar")
        self.pause_button: ttk.Button | None = None
        self.stop_button: ttk.Button | None = None
        self.start_button: ttk.Button | None = None

        self._build_layout()
        self._refresh_state()
        self.after(POLL_INTERVAL_MS, self._poll_log_queue)

    def _build_layout(self) -> None:
        header = ttk.Frame(self, padding=(24, 20, 24, 4))
        header.pack(fill="x")
        ttk.Label(
            header,
            text="Marcano Control",
            font=("Segoe UI", 20, "bold"),
        ).pack(anchor="w")
        ttk.Label(
            header,
            text="Backend FastAPI y aplicacion web local",
            font=("Segoe UI", 10),
        ).pack(anchor="w", pady=(2, 14))

        controls = ttk.Frame(self, padding=((24, 0, 24, 18)))
        controls.pack(fill="x")

        self.start_button = ttk.Button(
            controls,
            text="Iniciar aplicacion",
            command=self._handle_start,
            width=22,
        )
        self.start_button.pack(side="left", padx=(0, 8))

        self.pause_button = ttk.Button(
            controls,
            text="Pausar",
            command=self._handle_pause_resume,
            width=16,
            state="disabled",
        )
        self.pause_button.pack(side="left", padx=(0, 8))

        self.stop_button = ttk.Button(
            controls,
            text="Detener",
            command=self._handle_stop,
            width=16,
            state="disabled",
        )
        self.stop_button.pack(side="left", padx=(0, 8))

        open_logs_button = ttk.Button(
            controls,
            text="Abrir carpeta de logs",
            command=self._handle_open_log_folder,
            width=22,
        )
        open_logs_button.pack(side="right")

        status_frame = ttk.Labelframe(
            self,
            text="Estado",
            padding=(18, 12, 18, 18),
        )
        status_frame.pack(fill="x", padx=24, pady=(0, 16))

        ttk.Label(status_frame, textvariable=self.info_var).pack(anchor="w")
        ttk.Label(
            status_frame,
            textvariable=self.manager.url,
            foreground="#2563eb",
        ).pack(anchor="w", pady=(4, 0))

        logs_frame = ttk.Labelframe(
            self,
            text="Logs",
            padding=(18, 12, 18, 18),
        )
        logs_frame.pack(fill="both", expand=True, padx=24, pady=(0, 24))

        self.log_widget = scrolledtext.ScrolledText(
            logs_frame,
            height=20,
            state="disabled",
            font=("Consolas", 10),
            wrap="none",
            bg="#1f2937",
            fg="#e5e7eb",
            cursor="arrow",
        )
        self.log_widget.pack(fill="both", expand=True)

        ttk.Button(
            self,
            text="Abrir aplicacion en el navegador",
            command=self._handle_open_app,
        ).pack(fill="x", padx=24, pady=(0, 18))

    def _enqueue_log(self, message: str) -> None:
        self.log_queue.put(message)

    def _poll_log_queue(self) -> None:
        try:
            while True:
                message = self.log_queue.get_nowait()
                self._append_log(message)
        except queue.Empty:
            pass
        self._refresh_state()
        self.after(POLL_INTERVAL_MS, self._poll_log_queue)

    def _append_log(self, message: str) -> None:
        self.log_widget.configure(state="normal")
        self.log_widget.insert("end", f"{message}\n")
        self.log_widget.see("end")
        self.log_widget.configure(state="disabled")

    def _refresh_state(self) -> None:
        state = self.manager.state
        self.info_var.set(f"Estado actual: {state.value}")
        if self.start_button is not None:
            self.start_button.configure(state="disabled" if state != AppState.STOPPED else "normal")
        if self.pause_button is not None:
            self.pause_button.configure(
                state="normal" if state != AppState.STOPPED else "disabled",
                text="Reanudar" if state == AppState.PAUSED else "Pausar",
            )
        if self.stop_button is not None:
            self.stop_button.configure(state="normal" if state != AppState.STOPPED else "disabled")

    def _handle_start(self) -> None:
        try:
            self.manager.start()
        except RuntimeError as error:
            self._append_log(f"ERROR: {error}")

    def _handle_pause_resume(self) -> None:
        if self.manager.state == AppState.PAUSED:
            self.manager.resume()
        else:
            self.manager.pause()

    def _handle_stop(self) -> None:
        self.manager.stop()

    def _handle_open_app(self) -> None:
        webbrowser.open(self.manager.url)

    def _handle_open_log_folder(self) -> None:
        log_folder = self.manager.log_path.parent
        log_folder.mkdir(parents=True, exist_ok=True)
        if hasattr(os, "startfile"):
            os.startfile(log_folder)  # noqa: S606
        else:
            import subprocess

            subprocess.Popen(["xdg-open", str(log_folder)])

    def _on_close(self) -> None:
        if self.manager.state != AppState.STOPPED:
            self.manager.stop()
        self.destroy()


def discover_project_root() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parent.parent


def main() -> None:
    project_root = discover_project_root()
    app = MarcanoControl(project_root)
    app.mainloop()


if __name__ == "__main__":
    main()
