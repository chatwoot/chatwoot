# Password protected portals keep visitors signed in with a signed token in a cookie scoped
# to the portal. The token expires on its own and stops working when the password changes.
module PortalAccess
  extend ActiveSupport::Concern

  private

  def portal_access_granted?(portal)
    Portal.find_by_token_for(:access, cookies.encrypted[portal_access_cookie_name(portal)]) == portal
  end

  def grant_portal_access(portal)
    cookies.encrypted[portal_access_cookie_name(portal)] = {
      value: portal.generate_token_for(:access), httponly: true, secure: request.ssl?, same_site: :lax, expires: Portal::ACCESS_DURATION
    }
  end

  def portal_access_cookie_name(portal)
    "portal_access_#{portal.id}"
  end
end
