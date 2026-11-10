from __future__ import annotations

import os
import subprocess
import threading
from collections.abc import Callable
from datetime import datetime
from enum import Enum
from pathlib import Path

import psutil


class AppState(str, Enum):
    STOPPED = "Detenida"
    RUNNING = "En ejecucion"
    PAUSED = "En pausa"


class AppProcessManager:
    def __init__(
        self,
        project_root: Path,
        log_callback: Callable[[str], None],
        host: str = "127.0.0.1",
        port: int = 8000,
    ) -> None:
        self.project_root = project_root
        self.host = host
        self.port = port
        self.url = f"http://{host}:{port}"
        self.log_path = project_root / "data" / "logs" / "aplicativo.log"
        self._log_callback = log_callback
        self._process: subprocess.Popen[str] | None = None
        self._reader_thread: threading.Thread | None = None
        self._lock = threading.RLock()
        self._paused = False

    @property
    def state(self) -> AppState:
        with self._lock:
            if self._process is None or self._process.poll() is not None:
                return AppState.STOPPED
            return AppState.PAUSED if self._paused else AppState.RUNNING

    def validate(self) -> list[str]:
        problems: list[str] = []
        if not self._python_path.is_file():
            problems.append(f"No se encontro Python en {self._python_path}.")
        if not (self.project_root / "src" / "marcano" / "api.py").is_file():
            problems.append("No se encontro el backend en src/marcano/api.py.")
        if not (self.project_root / "flutter_app" / "build" / "web" / "index.html").is_file():
            problems.append(
                "La version web no esta compilada. Ejecuta scripts\\build_launcher.ps1."
            )
        return problems

    def start(self) -> None:
        with self._lock:
            if self.state != AppState.STOPPED:
                return
            problems = self.validate()
            if problems:
                raise RuntimeError(" ".join(problems))

            self.log_path.parent.mkdir(parents=True, exist_ok=True)
            environment = os.environ.copy()
            environment["PYTHONUNBUFFERED"] = "1"
            environment["PYTHONIOENCODING"] = "utf-8"
            environment["PYTHONPATH"] = str(self.project_root / "src")
            command = [
                str(self._python_path),
                "-m",
                "launcher.server",
                "--host",
                self.host,
                "--port",
                str(self.port),
                "--web-root",
                str(self.project_root / "flutter_app" / "build" / "web"),
            ]
            self._write_log(f"\n===== Sesion iniciada {datetime.now():%Y-%m-%d %H:%M:%S} =====")
            self._process = subprocess.Popen(
                command,
                cwd=self.project_root,
                env=environment,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                stdin=subprocess.DEVNULL,
                text=True,
                encoding="utf-8",
                errors="replace",
                bufsize=1,
                creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
            )
            self._paused = False
            self._reader_thread = threading.Thread(
                target=self._read_output,
                args=(self._process,),
                daemon=True,
                name="marcano-log-reader",
            )
            self._reader_thread.start()
            self._write_log(f"Aplicacion iniciada con PID {self._process.pid}. URL: {self.url}")

    def pause(self) -> None:
        with self._lock:
            if self.state != AppState.RUNNING or self._process is None:
                return
            process = psutil.Process(self._process.pid)
            children = process.children(recursive=True)
            for child in children:
                child.suspend()
            process.suspend()
            self._paused = True
            self._write_log("Aplicacion pausada. Reanudala para volver a atender peticiones.")

    def resume(self) -> None:
        with self._lock:
            if self.state != AppState.PAUSED or self._process is None:
                return
            process = psutil.Process(self._process.pid)
            process.resume()
            for child in process.children(recursive=True):
                child.resume()
            self._paused = False
            self._write_log("Aplicacion reanudada.")

    def stop(self) -> None:
        with self._lock:
            process = self._process
            if process is None:
                return
            if process.poll() is None:
                if self._paused:
                    try:
                        psutil.Process(process.pid).resume()
                    except psutil.NoSuchProcess:
                        pass
                    self._paused = False
                self._write_log("Deteniendo aplicacion...")
                process.terminate()
                try:
                    process.wait(timeout=6)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=3)
                self._write_log(f"Aplicacion detenida. Codigo de salida: {process.returncode}.")
            self._process = None
            self._paused = False

    def _read_output(self, process: subprocess.Popen[str]) -> None:
        if process.stdout is not None:
            with process.stdout:
                for line in process.stdout:
                    self._write_log(line.rstrip())
        return_code = process.wait()
        with self._lock:
            if self._process is process:
                self._process = None
                self._paused = False
        self._write_log(f"El proceso finalizo. Codigo de salida: {return_code}.")

    def _write_log(self, message: str) -> None:
        timestamped = f"[{datetime.now():%H:%M:%S}] {message}"
        try:
            with self.log_path.open("a", encoding="utf-8") as log_file:
                log_file.write(f"{timestamped}\n")
        except OSError:
            pass
        self._log_callback(timestamped)

    @property
    def _python_path(self) -> Path:
        windows_python = self.project_root / ".venv" / "Scripts" / "python.exe"
        if windows_python.is_file():
            return windows_python
        return self.project_root / ".venv" / "bin" / "python"
