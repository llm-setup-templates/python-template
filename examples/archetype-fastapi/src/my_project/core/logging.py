"""Loguru-based logging setup — env-aware console/JSON + file rotation."""
import logging
import sys
from pathlib import Path
from typing import override

from loguru import logger


def setup_logging(debug: bool = False) -> None:
    logger.remove()
    if debug:
        logger.add(sys.stdout, level="DEBUG", colorize=True,
            format="<green>{time:HH:mm:ss}</green> | <level>{level:<8}</level> | "
            "<cyan>{name}</cyan>:<cyan>{line}</cyan> | <level>{message}</level>")
    else:
        logger.add(sys.stdout, level="INFO", serialize=True)

    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    logger.add(log_dir / "error.log", level="ERROR", rotation="10 MB", retention="7 days", serialize=True)

    class InterceptHandler(logging.Handler):
        @override
        def emit(self, record: logging.LogRecord) -> None:
            try:
                level = logger.level(record.levelname).name
            except ValueError:
                level = record.levelno
            logger.opt(depth=2, exception=record.exc_info).log(level, record.getMessage())

    logging.basicConfig(handlers=[InterceptHandler()], level=0, force=True)
