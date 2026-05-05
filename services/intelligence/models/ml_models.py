from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Tuple

import numpy as np
import structlog
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler

log = structlog.get_logger()

MODEL_PATH = Path(os.getenv("MODEL_DIR", "/tmp/meridian_models"))

TLD_SCORES: dict[str, float] = {
    "com": 1.0,
    "co.uk": 0.9,
    "org": 0.85,
    "net": 0.8,
    "io": 0.75,
    "co": 0.7,
    "de": 0.65,
    "fr": 0.6,
    "es": 0.6,
    "it": 0.55,
    "nl": 0.55,
    "eu": 0.5,
    "app": 0.45,
    "ai": 0.7,
    "tech": 0.4,
}


def _tld_score(domain: str) -> float:
    parts = domain.split(".")
    if len(parts) >= 3:
        tld = ".".join(parts[-2:])
        if tld in TLD_SCORES:
            return TLD_SCORES[tld]
    if len(parts) >= 2:
        return TLD_SCORES.get(parts[-1], 0.3)
    return 0.3


def _extract_features(domain: str, estimated_backlinks: int, crawl_frequency: float) -> np.ndarray:
    has_www = 1.0 if domain.startswith("www.") else 0.0
    clean = domain.removeprefix("www.")
    parts = clean.split(".")
    domain_name = parts[0] if parts else clean
    domain_length = float(len(domain_name))
    tld_score = _tld_score(clean)
    log_backlinks = float(np.log1p(estimated_backlinks))
    return np.array([[domain_length, tld_score, has_www, log_backlinks, crawl_frequency]])


def _generate_synthetic_data(n_samples: int = 2000) -> Tuple[np.ndarray, np.ndarray]:
    rng = np.random.default_rng(42)

    domain_lengths = rng.uniform(3, 30, n_samples)
    tld_scores = rng.choice(list(TLD_SCORES.values()), n_samples)
    has_www = rng.integers(0, 2, n_samples).astype(float)
    log_backlinks = rng.uniform(0, 15, n_samples)
    crawl_freq = rng.uniform(0.0, 1.0, n_samples)

    X = np.column_stack([domain_lengths, tld_scores, has_www, log_backlinks, crawl_freq])

    monthly_visits = (
        tld_scores * 50_000
        + np.exp(log_backlinks) * 100
        + crawl_freq * 200_000
        + (30 - domain_lengths) * 1_000
        + has_www * 5_000
        + rng.normal(0, 10_000, n_samples)
    ).clip(0)

    return X, monthly_visits


class SimpleTrafficEstimator:
    def __init__(self) -> None:
        self._model: RandomForestRegressor | None = None
        self._scaler: StandardScaler | None = None

    def load_or_train(self) -> None:
        MODEL_PATH.mkdir(parents=True, exist_ok=True)
        log.info("meridian.ml.traffic_estimator.training", n_samples=2000)
        self._train()

    def _train(self) -> None:
        X, y = _generate_synthetic_data(2000)

        self._scaler = StandardScaler()
        X_scaled = self._scaler.fit_transform(X)

        self._model = RandomForestRegressor(
            n_estimators=100,
            max_depth=12,
            min_samples_leaf=5,
            random_state=42,
            n_jobs=-1,
        )
        self._model.fit(X_scaled, y)
        log.info("meridian.ml.traffic_estimator.trained")

    def predict(self, features: np.ndarray) -> Tuple[float, float]:
        if self._model is None or self._scaler is None:
            raise RuntimeError("Model not trained - call load_or_train() first")

        X_scaled = self._scaler.transform(features)

        tree_predictions = np.array(
            [tree.predict(X_scaled)[0] for tree in self._model.estimators_]
        )

        estimate = float(np.mean(tree_predictions))
        std_dev = float(np.std(tree_predictions))
        confidence = max(0.1, min(0.99, 1.0 - (std_dev / (estimate + 1))))

        return max(0.0, estimate), confidence

    def predict_for_domain(
        self,
        domain: str,
        estimated_backlinks: int = 0,
        crawl_frequency: float = 0.5,
    ) -> Tuple[float, float]:
        features = _extract_features(domain, estimated_backlinks, crawl_frequency)
        return self.predict(features)
