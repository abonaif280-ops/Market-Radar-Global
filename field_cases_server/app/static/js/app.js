// تأكيد قبل الإجراءات الحساسة (النماذج والأزرار التي تحمل data-confirm).
document.addEventListener("submit", (event) => {
  const button = event.submitter;
  const message = (button && button.dataset.confirm) || event.target.dataset.confirm;
  if (message && !window.confirm(message)) event.preventDefault();
});

// نسخ النص: clipboard يعمل فقط على HTTPS أو localhost، والبديل للشبكة الداخلية بـ HTTP.
document.addEventListener("click", async (event) => {
  const button = event.target.closest("[data-copy]");
  if (!button) return;
  const field = document.getElementById(button.dataset.copy);
  const status = document.getElementById("copy-status");
  let ok = false;
  try {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(field.value);
      ok = true;
    }
  } catch (e) { ok = false; }
  if (!ok) {
    field.focus();
    field.select();
    ok = document.execCommand && document.execCommand("copy");
  }
  if (status) status.textContent = ok ? "نُسخ النص" : "حدّد النص وانسخه يدويًا (Ctrl+C)";
});

// نموذج الحالة: حقول النوع، المراكز حسب المحافظة، حقول العدد.
(function () {
  const form = document.getElementById("case-form");
  if (!form) return;

  function selectedType() {
    const checked = form.querySelector('input[name="case_type_id"]:checked');
    return checked ? checked.value : "";
  }
  function syncTypeFields() {
    const type = selectedType();
    form.querySelectorAll(".type-fields").forEach((box) => {
      const on = box.dataset.type === type;
      box.hidden = !on;
      box.querySelectorAll("input, select, textarea").forEach((el) => { el.disabled = !on; });
    });
  }
  function syncCenters() {
    const gov = form.querySelector("#governorate");
    const center = form.querySelector("#center");
    if (!gov || !center) return;
    Array.from(center.options).forEach((opt) => {
      if (!opt.value) return;
      const visible = !opt.dataset.parent || opt.dataset.parent === gov.value;
      opt.hidden = !visible;
      opt.disabled = !visible;
      if (!visible && opt.selected) center.value = "";
    });
  }
  function syncToggles() {
    form.querySelectorAll("[data-toggles]").forEach((box) => {
      const target = document.getElementById(box.dataset.toggles);
      if (target) target.disabled = !box.checked;
    });
  }
  form.addEventListener("change", () => { syncTypeFields(); syncCenters(); syncToggles(); });
  syncTypeFields(); syncCenters(); syncToggles();
})();
