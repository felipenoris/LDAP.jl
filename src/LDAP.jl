
module LDAP

import Libdl

include("enums.jl")
include("types.jl")
include("libldap.jl")

function __init__()
    check_deps()
end

function is_ldap_url(url::AbstractString) :: Bool
    ldap_is_ldap_url(url) != 0
end

function get_error_message(error_code::Integer)
    return unsafe_string(ldap_err2string(error_code))
end

function get_error_message(err::AuthErr)
    return get_error_message(err.err_code)
end

function error_check(err::Integer)
    if err != 0
        error("LDAP Error Code $err: $(get_error_message(err))")
    end
end

function LDAPConnection(uri::AbstractString; protocol::LDAPVersion=LDAP_VERSION3)
    @assert is_ldap_url(uri) "$uri is not a valid LDAP URL."
    ldp_handle_ref = Ref{Ptr{Cvoid}}()
    err = ldap_initialize(ldp_handle_ref, uri)
    error_check(err)
    result = LDAPConnection(ldp_handle_ref[], uri)
    set_protocol_version(result, protocol)
    return result
end

function set_protocol_version(ldap::LDAPConnection, protocol::LDAPVersion)
    err = ldap_set_option(ldap.handle, LDAP_OPT_PROTOCOL_VERSION, protocol)
    error_check(err)
end

function get_protocol_version(ldap::LDAPConnection)
    out_int = Ref{Cint}(0)
    err = ldap_get_option(ldap.handle, LDAP_OPT_PROTOCOL_VERSION, out_int)
    return LDAPVersion(out_int[])
end

@inline parse_opt_string(str::Cstring) = str == C_NULL ? nothing : unsafe_string(str)

@inline function parse_null_terminated_string_vector(ptr::Ptr{Ptr{UInt8}}) :: Vector{String}
    result = Vector{String}()

    if ptr == C_NULL
        return result
    end

    cstring_vector = unsafe_wrap(Array, ptr, (10,))

    local i = 1
    while true
        p = cstring_vector[i]
        if p == C_NULL
            break
        else
            push!(result, unsafe_string(p))
        end

        i += 1

        if i > length(cstring_vector)
            cstring_vector = unsafe_wrap(Vector{Cstring}, ptr, (length(cstring_vector) * 2,))
        end
    end

    return result
end

function URL(url::AbstractString)

    ldap_url_desc_handle_ref = Ref{Ptr{LDAPURLDesc}}()
    err = ldap_url_parse(url, ldap_url_desc_handle_ref)
    error_check(err)
    handle = ldap_url_desc_handle_ref[]

    local result::URL

    try
        ldap_url_desc = unsafe_load(ldap_url_desc_handle_ref[])

        lud_scheme = unsafe_string(ldap_url_desc.lud_scheme)
        lud_host = unsafe_string(ldap_url_desc.lud_host)
        lud_port = ldap_url_desc.lud_port
        lud_dn = parse_opt_string(ldap_url_desc.lud_dn)
        lud_attrs = parse_null_terminated_string_vector(ldap_url_desc.lud_attrs)
        lud_scope = ldap_url_desc.lud_scope
        lud_filter = parse_opt_string(ldap_url_desc.lud_filter)
        lud_exts = parse_null_terminated_string_vector(ldap_url_desc.lud_exts)
        lud_crit_exts = ldap_url_desc.lud_crit_exts

        result = URL(lud_scheme, lud_host, lud_port, lud_dn, lud_attrs, lud_scope, lud_filter, lud_exts, lud_crit_exts)

    finally
        ldap_free_urldesc(handle)
    end

    return result
end

function simple_bind(ldap::LDAPConnection, who::AbstractString, password::AbstractString)
    err = ldap_simple_bind_s(ldap.handle, who, password)
    error_check(err)
    nothing
end

function unbind(ldap::LDAPConnection)
    err = ldap_unbind_s(ldap.handle)
    error_check(err)
end

function authenticate(uri::AbstractString, who::AbstractString, password::AbstractString;
        protocol::LDAPVersion=LDAP_VERSION3) :: AuthenticationResult

    ldap = LDAPConnection(uri, protocol=protocol)
    err = ldap_simple_bind_s(ldap.handle, who, password)
    result = new_authentication_result(uri, who, err)
    unbind(ldap)
    return result
end

function new_authentication_result(uri::AbstractString, who::AbstractString, err::Integer)
    if err == 0
        return AuthOk(uri, who)
    else
        return AuthErr(uri, who, err)
    end
end

end # module
