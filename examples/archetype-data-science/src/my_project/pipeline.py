"""Generic data-science pipeline — numpy/pandas/scipy."""

from __future__ import annotations

import numpy as np
import numpy.typing as npt


class SignalPipeline:
    """Process raw signal data with configurable normalization."""

    def __init__(self, sample_rate: int = 256) -> None:
        self.sample_rate = sample_rate

    def normalize(self, signal: npt.NDArray[np.float64]) -> npt.NDArray[np.float64]:
        """Normalize signal to zero mean and unit variance."""
        if signal.size == 0:
            raise ValueError("signal must not be empty")
        mean = signal.mean()
        std = signal.std()
        if std == 0:
            raise ValueError("signal has zero variance — normalization undefined")
        return (signal - mean) / std
