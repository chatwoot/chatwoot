# Password protected portals keep visitors signed in with an encrypted cookie scoped to the
# portal. The cookie stores the portal's password digest, so changing the password
# signs everyone out.
module PortalAccess
  extend ActiveSupport::Concern

  PORTAL_ACCESS_DURATION = 30.days

  private

  def portal_access_granted?(portal)
    token = cookies.encrypted[portal_access_cookie_name(portal)]
    token.present? && ActiveSupport::SecurityUtils.secure_compare(token, portal.password_digest)
  end

  def grant_portal_access(portal)
    cookies.encrypted[portal_access_cookie_name(portal)] = {
      value: portal.password_digest, httponly: true, secure: request.ssl?, same_site: :lax, expires: PORTAL_ACCESS_DURATION
    }
  end

  def portal_access_cookie_name(portal)
    "portal_access_#{portal.id}"
  end
end
