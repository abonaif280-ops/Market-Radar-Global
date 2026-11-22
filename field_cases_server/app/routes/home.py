from __future__ import annotations

from fastapi import APIRouter, Request

from ..web import current_session, render, tx

router = APIRouter()


@router.get("/")
def home(request: Request):
    with tx(request) as db:
        current_session(request, db)
    return render(request, "home.html")
