import sys
import os
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from engines.opportunity_engine import OpportunityEngine
from models.schemas import OpportunityFilters


@pytest.fixture
def engine():
    return OpportunityEngine()


def test_score_formula_balanced(engine):
    score = engine._score(
        traffic_gap=0.5,
        fx_stability=0.5,
        competitor_weakness=0.5,
        market_growth=0.5,
    )
    assert score == pytest.approx(50.0, abs=0.5)


def test_score_formula_max_inputs(engine):
    score = engine._score(
        traffic_gap=1.0,
        fx_stability=1.0,
        competitor_weakness=1.0,
        market_growth=1.0,
    )
    assert score == pytest.approx(100.0, abs=0.1)


def test_score_formula_zero_inputs(engine):
    score = engine._score(
        traffic_gap=0.0,
        fx_stability=0.0,
        competitor_weakness=0.0,
        market_growth=0.0,
    )
    assert score == pytest.approx(0.0, abs=0.1)


def test_score_clamped_to_100(engine):
    score = engine._score(
        traffic_gap=2.0,
        fx_stability=2.0,
        competitor_weakness=2.0,
        market_growth=2.0,
    )
    assert score <= 100.0


def test_score_traffic_gap_weight(engine):
    score = engine._score(traffic_gap=1.0, fx_stability=0.0, competitor_weakness=0.0, market_growth=0.0)
    assert score == pytest.approx(30.0, abs=0.5)


def test_score_fx_stability_weight(engine):
    score = engine._score(traffic_gap=0.0, fx_stability=1.0, competitor_weakness=0.0, market_growth=0.0)
    assert score == pytest.approx(25.0, abs=0.5)


def test_seed_opportunities_returns_list(engine):
    opps = engine._seed_opportunities()
    assert isinstance(opps, list)
    assert len(opps) > 0


def test_seed_opportunities_valid_scores(engine):
    for opp in engine._seed_opportunities():
        assert 0.0 <= opp.score <= 100.0


def test_apply_filters_no_market_returns_all(engine):
    opps = engine._seed_opportunities()
    filters = OpportunityFilters(market=None)
    result = engine._apply_filters(opps, filters)
    assert len(result) > 0


def test_apply_filters_market_narrows(engine):
    opps = engine._seed_opportunities()
    filters = OpportunityFilters(market="saas")
    result = engine._apply_filters(opps, filters)
    assert all(o.market.lower() == "saas" for o in result)


def test_apply_filters_min_score_excludes_low(engine):
    opps = engine._seed_opportunities()
    filters = OpportunityFilters(min_score=99.0)
    result = engine._apply_filters(opps, filters)
    assert all(o.score >= 99.0 for o in result)


def test_apply_filters_max_results_respected(engine):
    opps = engine._seed_opportunities()
    filters = OpportunityFilters(max_results=2)
    result = engine._apply_filters(opps, filters)
    assert len(result) <= 2
