import sys
import os
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from engines.domain_engine import DomainEngine


@pytest.fixture
def engine():
    return DomainEngine()


def test_normalise_strips_http():
    e = DomainEngine()
    assert e._normalise("http://shopify.com") == "shopify.com"


def test_normalise_strips_https():
    e = DomainEngine()
    assert e._normalise("https://shopify.com/path") == "shopify.com"


def test_normalise_strips_www():
    e = DomainEngine()
    assert e._normalise("www.shopify.com") == "shopify.com"


def test_normalise_strips_https_www():
    e = DomainEngine()
    assert e._normalise("https://www.shopify.com/blog") == "shopify.com"


def test_normalise_lowercase():
    e = DomainEngine()
    assert e._normalise("SHOPIFY.COM") == "shopify.com"


def test_normalise_plain_domain_unchanged():
    e = DomainEngine()
    assert e._normalise("etsy.com") == "etsy.com"


def test_is_valid_accepts_tld():
    e = DomainEngine()
    assert e._is_valid("shopify.com") is True


def test_is_valid_rejects_bare_word():
    e = DomainEngine()
    assert e._is_valid("shopify") is False


def test_is_valid_rejects_ip_address():
    e = DomainEngine()
    assert e._is_valid("192.168.1.1") is False


def test_is_valid_rejects_empty():
    e = DomainEngine()
    assert e._is_valid("") is False


def test_is_valid_rejects_localhost():
    e = DomainEngine()
    assert e._is_valid("localhost") is False


def test_is_valid_accepts_subdomain():
    e = DomainEngine()
    assert e._is_valid("app.shopify.com") is True
