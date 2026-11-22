"""نفس توقعات اختبارات تطبيق الجوال (case_text_composer_test.dart و
template_engine_test.dart): السيرفر والجوال يكتبان النص نفسه حرفيًا."""

from __future__ import annotations

from datetime import datetime

import pytest

from app.cases import service, template_engine as te
from app.cases.service import CaseForm


def lid(key: str, code: str) -> str:
    return f"{key}:{code}"


@pytest.fixture
def choices(app):
    with app.state.session_factory() as db:
        return service.load_choices(db)


def compose(app, choices, data: CaseForm) -> str:
    with app.state.session_factory() as db:
        return service.compose(db, data, choices, photo_count=0)


def requirements_example() -> CaseForm:
    return CaseForm(
        case_type_id=lid("case_type", "SOLID_OBJECT"),
        occurred_local=datetime(2026, 9, 25, 19, 30),
        governorate_id=lid("governorate", "BADR"),
        center_id=lid("center", "RAYES"),
        location_text="جنوب مركز الرايس",
        report_source_id=lid("report_source", "911"),
        extra={"object_state": "أجزاء من جسم صلب", "has_fire": True},
        party_ids=[lid("party", "EOD"), lid("party", "CIVIL_DEF")],
    )


def test_requirements_example(app, choices):
    assert compose(app, choices, requirements_example()) == (
        "عند الساعة 7:30 مساءً ورد بلاغ من العمليات الموحدة (911) عن العثور على "
        "جسم صلب جنوب مركز الرايس، وبالانتقال للموقع اتضح وجود أجزاء من جسم صلب "
        "تنبعث منها نيران، دون تسجيل إصابات أو وفيات، وجرى إبلاغ الدفاع المدني "
        "وإدارة الأسلحة والمتفجرات لإكمال اللازم كل فيما يخصه."
    )


def test_injuries_damage_and_action(app, choices):
    data = requirements_example()
    del data.extra["has_fire"]
    data.has_injuries, data.injuries_count = True, 2
    data.has_damage, data.damage_description = True, "تضرر سيارة"
    data.action_taken = "وتم تطويق الموقع"
    assert compose(app, choices, data) == (
        "عند الساعة 7:30 مساءً ورد بلاغ من العمليات الموحدة (911) عن العثور على "
        "جسم صلب جنوب مركز الرايس، وبالانتقال للموقع اتضح وجود أجزاء من جسم صلب، "
        "ونتج عن ذلك إصابتان، مع وجود أضرار (تضرر سيارة)، وتم تطويق الموقع، "
        "وجرى إبلاغ الدفاع المدني وإدارة الأسلحة والمتفجرات لإكمال اللازم كل فيما يخصه."
    )


def test_sparse_draft(app, choices):
    data = CaseForm(
        case_type_id=lid("case_type", "SECURITY_CASE"),
        occurred_local=datetime(2026, 9, 25, 9, 5),
        governorate_id=lid("governorate", "YNB"),
    )
    assert compose(app, choices, data) == (
        "عند الساعة 9:05 صباحًا ورد بلاغ عن حالة أمنية بمحافظة ينبع، دون تسجيل إصابات أو وفيات."
    )


def test_fire_and_drone(app, choices):
    fire = CaseForm(
        case_type_id=lid("case_type", "FIRE"),
        occurred_local=datetime(2026, 9, 25, 22, 0),
        center_id=lid("center", "RAYES"),
        report_source_id=lid("report_source", "PATROL"),
        extra={"fire_size": "محدود", "fire_controlled": True},
        has_deaths=True,
        deaths_count=1,
    )
    assert compose(app, choices, fire) == (
        "عند الساعة 10:00 مساءً ورد بلاغ من دورية ميدانية عن نشوب حريق محدود "
        "في مركز الرايس، وتمت السيطرة عليه، ونتج عن ذلك حالة وفاة واحدة."
    )
    drone = CaseForm(
        case_type_id=lid("case_type", "DRONE"),
        occurred_local=datetime(2026, 9, 25, 13, 15),
        location_text="شمال طريق الهجرة",
        extra={"drone_state": "محطمة"},
        party_ids=[lid("party", "EOD")],
    )
    assert compose(app, choices, drone) == (
        "عند الساعة 1:15 مساءً ورد بلاغ عن سقوط طائرة مسيرة شمال طريق الهجرة، "
        "وبالانتقال للموقع اتضح أنها محطمة، دون تسجيل إصابات أو وفيات، وجرى إبلاغ "
        "إدارة الأسلحة والمتفجرات لإكمال اللازم كل فيما يخصه."
    )


def test_engine_sections_and_values():
    t = "{{#حريق}}يوجد حريق{{/حريق}}{{^حريق}}لا حريق{{/حريق}}"
    assert te.render(t, {"حريق": True}) == "يوجد حريق"
    assert te.render(t, {"حريق": False}) == "لا حريق"
    assert te.render(t, {"حريق": 0}) == "لا حريق"
    assert te.render(t, {"حريق": 3}) == "يوجد حريق"
    assert te.render(t, {"حريق": "  "}) == "لا حريق"
    assert te.render(t, {}) == "لا حريق"
    n = "{{#أ}}أ{{#ب}} وب{{/ب}}{{/أ}}"
    assert te.render(n, {"أ": 1, "ب": 1}) == "أ وب"
    assert te.render(n, {"أ": 1}) == "أ"
    assert te.render(n, {"ب": 1}) == ""
    assert te.render("{{x}}", {"x": True}) == "نعم"
    assert te.render("{{x}}", {"x": ["أ", "ب"]}) == "أ، ب"
    assert te.render("{{ # x }}نعم{{ / x }}", {"x": 1}) == "نعم"
    assert te.render("بلاغ {{النوع}} في {{المكان}}{{غير_موجود}}.", {"النوع": "حريق", "المكان": "ينبع"}) == "بلاغ حريق في ينبع."


def test_engine_cleanup():
    assert te.clean_up("بلاغ  من   جهة ، في ينبع") == "بلاغ من جهة، في ينبع"
    assert te.clean_up("أ،، ب، ، ج") == "أ، ب، ج"
    assert te.clean_up("نهاية،.") == "نهاية."
    assert te.clean_up("، بداية") == "بداية"
    assert te.clean_up("أضرار () هنا") == "أضرار هنا"
    assert te.clean_up("الوقت 7:30 مساءً") == "الوقت 7:30 مساءً"


def test_casualty_phrases():
    p = service.casualties_phrase
    assert p(0, 0) == "دون تسجيل إصابات أو وفيات"
    assert p(1, 0) == "ونتج عن ذلك إصابة واحدة"
    assert p(2, 0) == "ونتج عن ذلك إصابتان"
    assert p(5, 0) == "ونتج عن ذلك (5) إصابات"
    assert p(12, 0) == "ونتج عن ذلك (12) إصابة"
    assert p(0, 2) == "ونتج عن ذلك حالتا وفاة"
    assert p(3, 1) == "ونتج عن ذلك (3) إصابات وحالة وفاة واحدة"


def test_coordinates_accept_arabic_digits():
    from app.cases.formatting import format_coordinates, parse_coordinates

    assert parse_coordinates("٢٤٫٤٦٨٢٤٥، ٣٩٫٦١٢٣٥٤") == (24.468245, 39.612354)
    assert parse_coordinates("24.468245 39.612354") == (24.468245, 39.612354)
    assert parse_coordinates("95, 10") is None
    assert parse_coordinates("abc") is None
    assert format_coordinates(24.4682451, 39.6) == "24.468245, 39.600000"


def test_display_code_matches_mobile_format():
    code = service.display_code_for("a72f91c3-0000-4000-8000-000000000000", datetime(2026, 9, 25, 10))
    assert code == "EVT-20260925-A72F91"
