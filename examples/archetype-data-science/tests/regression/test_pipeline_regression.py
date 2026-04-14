"""Regression tests for SignalPipeline.

NOTE: Data-science archetype does NOT use syrupy snapshots for floating-point
regression tests. Use numpy.testing.assert_allclose with explicit tolerances.
syrupy bit-exact snapshots are unreliable for floating-point numeric outputs.
"""

import numpy as np
import numpy.testing as npt_testing
import pytest

from my_project.pipeline import SignalPipeline


@pytest.fixture()
def pipeline() -> SignalPipeline:
    return SignalPipeline(sample_rate=256)


def test_normalize_zero_mean(pipeline: SignalPipeline) -> None:
    signal = np.array([1.0, 2.0, 3.0, 4.0, 5.0])
    result = pipeline.normalize(signal)
    npt_testing.assert_allclose(result.mean(), 0.0, atol=1e-10)


def test_normalize_unit_variance(pipeline: SignalPipeline) -> None:
    signal = np.array([1.0, 2.0, 3.0, 4.0, 5.0])
    result = pipeline.normalize(signal)
    npt_testing.assert_allclose(result.std(), 1.0, atol=1e-10)


def test_normalize_empty_raises(pipeline: SignalPipeline) -> None:
    with pytest.raises(ValueError, match="must not be empty"):
        pipeline.normalize(np.array([]))
