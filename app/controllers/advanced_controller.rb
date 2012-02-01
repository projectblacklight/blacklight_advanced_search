# This class should NOT be generated into local app. If you generated
# into local app in a previous version, remove that, config is done
# in CatalogController now.
#
# Note that this NEEDS to sub-class CatalogController, so it gets any
# custom searching behavior you've added, and uses when fetching facets
# etc. It does that right now because BlacklightAdvancedSearch::AdvancedController
# is hard-coded to subclass CatalogController. 
#
# TODO: 
# This seperate controller may not need to exist at all -- it just exists
# to provide the advanced search form (and fetching of facets to display
# on that form). Instead, mix-in a new "advanced" action to CatalogController?
# (Make a backwards compat route though). 
#
# Alternately, if this does exist as a seperate controller, it should 
# _directly_ < CatalogController, and BlacklightAdvancedSearch::AdvancedController
# should be a mix-in that does not assume parent controller. Then, if you have
# multi-controllers, you just need to create new `AdvancedControllerForX < XController`
# which still mixes in BlacklightAdvancedSearch::AdvancedController. There
# are probably some other edges that need to be smoothed for that approach, but
# that'd be the direction. 
class AdvancedController < BlacklightAdvancedSearch::AdvancedController

  copy_blacklight_config_from(CatalogController)

end
