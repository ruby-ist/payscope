# Pagy initializer. See https://ddnexus.github.io/pagy/toolbox/configuration/initializer/
#
# Pagy 43 configures through Pagy::OPTIONS (the older Pagy::DEFAULT[:items] and
# the `trim` extra no longer exist). Page-1 links drop the ?page param already,
# via `page_url(:first)`, so no extra is needed for clean bookmarkable URLs.
Pagy::OPTIONS[:limit] = 25

Pagy::OPTIONS.freeze
