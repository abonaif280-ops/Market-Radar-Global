"""محرك القوالب — نقل مطابق لـ template_engine.dart في تطبيق الجوال.

- {{الوقت}} تُستبدل بقيمة المتغير (فارغ إن لم يوجد).
- {{#وجود_حريق}} ... {{/وجود_حريق}} يظهر إذا كانت القيمة "صحيحة".
- {{^وجود_حريق}} ... {{/وجود_حريق}} يظهر إذا كانت القيمة "فارغة".
بعد الاستبدال يُنظَّف النص من المسافات وعلامات الترقيم الزائدة.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any

_TAG = re.compile(r"\{\{\s*([#^/]?)\s*([^{}]+?)\s*\}\}")


def is_truthy(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value > 0
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, (list, tuple, set)):
        return len(value) > 0
    return True


def stringify(value: Any) -> str:
    if value is None:
        return ""
    if value is True:
        return "نعم"
    if value is False:
        return "لا"
    if isinstance(value, (list, tuple)):
        return "، ".join(str(v) for v in value)
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return str(value).strip()


def clean_up(text: str) -> str:
    result = re.sub(r"[ \t]+", " ", text)
    result = re.sub(r" +([،,.:؛])", r"\1", result)
    result = re.sub(r" *\n *", "\n", result)
    result = re.sub(r"([،,])(\s*[،,])+", r"\1", result)
    result = re.sub(r"[،,]\s*\.", ".", result)
    result = re.sub(r"\(\s*\)", "", result)
    result = re.sub(r"\A[\s،,.]+", "", result)
    result = re.sub(r"[ ،,]+\Z", "", result)
    return re.sub(r"[ \t]+", " ", result).strip()


@dataclass
class _Section:
    name: str
    inverted: bool
    children: list = field(default_factory=list)


def _parse(template: str) -> list:
    root: list = []
    stack: list[tuple[_Section, list]] = []
    current = root
    position = 0
    for match in _TAG.finditer(template):
        if match.start() > position:
            current.append(template[position : match.start()])
        position = match.end()
        kind, name = match.group(1), match.group(2)
        if kind in ("#", "^"):
            section = _Section(name, inverted=kind == "^")
            current.append(section)
            stack.append((section, current))
            current = section.children
        elif kind == "/":
            index = next((i for i in range(len(stack) - 1, -1, -1) if stack[i][0].name == name), -1)
            if index < 0:
                continue  # إغلاق بلا فتح مطابق يُتجاهل
            current = stack[index][1]
            del stack[index:]
        else:
            current.append(("var", name))
    if position < len(template):
        current.append(template[position:])
    return root


def _render(nodes: list, variables: dict[str, Any], out: list[str]) -> None:
    for node in nodes:
        if isinstance(node, str):
            out.append(node)
        elif isinstance(node, tuple):
            out.append(stringify(variables.get(node[1])))
        elif is_truthy(variables.get(node.name)) != node.inverted:
            _render(node.children, variables, out)


def render(template: str, variables: dict[str, Any]) -> str:
    out: list[str] = []
    _render(_parse(template), variables, out)
    return clean_up("".join(out))
