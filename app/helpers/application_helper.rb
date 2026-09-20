module ApplicationHelper
  def icon(name, css_class: "size-4 shrink-0")
    render "shared/icons/#{name}", css_class: css_class
  end

  # Icon plus a visible label. There is deliberately no label-less variant —
  # every actionable button carries both (docs/design_notes.md §4).
  def icon_label(name, label)
    safe_join([ icon(name), tag.span(label) ])
  end

  # Marks the current section with both the visual treatment and aria-current,
  # from one piece of markup (docs/design_notes.md §7).
  def nav_link_to(label, path, controller)
    active = controller_name == controller

    link_to label, path,
            class: class_names("rounded-md px-3 py-1.5 transition-colors",
                               active ? "text-nav-active" : "text-nav-text hover:text-nav-active"),
            aria: { current: ("page" if active) }
  end

  # Clips overflowing text while keeping the full value available to mouse users
  # (title) and screen readers (aria-label) — docs/design_notes.md §6.
  def truncated_text(value, css_class: nil)
    tag.span(value, class: [ "truncate", css_class ], title: value, aria: { label: value })
  end
end
