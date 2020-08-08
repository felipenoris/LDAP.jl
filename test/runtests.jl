
using Test

import LDAP

@testset "URL" begin

    @testset "Equality" begin
        sample_url_a = LDAP.URL("ldap", "ds.example.com", 389, "dc=example,dc=com", ["a", "b"] , 0, nothing, ["a", "b"], 0)
        sample_url_b = LDAP.URL("ldap", "ds.example.com", 389, "dc=example,dc=com", ["a", "b"] , 0, nothing, ["a", "b"], 0)
        @test sample_url_a == sample_url_b

        sample_url_c = LDAP.URL("ldap", "ds.example.com", 389, "dc=example,dc=com", Vector{String}(), 0, nothing, ["a", "b"], 0)
        sample_url_d = LDAP.URL("ldap", "ds.example.com", 389, "dc=example,dc=com", Vector{String}(), 0, nothing, ["a", "b"], 0)
        @test sample_url_c == sample_url_d

        @test sample_url_a != sample_url_c
    end

    url_strings = [
        "ldap://ds.example.com:389/dc=example,dc=com",
        "ldap://ds.example.com:389",
        "ldap://ds.example.com:389/dc=example,dc=com?givenName,sn,cn?sub?(uid=john.doe)"
    ]

    expected_urls = [
        LDAP.URL("ldap", "ds.example.com", 389, "dc=example,dc=com", Vector{String}(), 0, nothing, Vector{String}(), 0),
        LDAP.URL("ldap", "ds.example.com", 389, nothing, Vector{String}(), 0, nothing, Vector{String}(), 0),
        LDAP.URL("ldap", "ds.example.com", 389, "dc=example,dc=com", ["givenName", "sn", "cn"], 2, "(uid=john.doe)", Vector{String}(), 0)
    ]

    @assert length(url_strings) == length(expected_urls)

    for i in 1:length(url_strings)
        url_s = url_strings[i]
        @test LDAP.is_ldap_url(url_s)
        url = LDAP.URL(url_s)
        @test url == expected_urls[i]
    end

    @test !LDAP.is_ldap_url("https://github.com")
end

@testset "LDAPConnection" begin
    ldap = LDAP.LDAPConnection("ldap://ds.example.com:389")
    @test LDAP.get_protocol_version(ldap) == LDAP.LDAP_VERSION3

    ldap = LDAP.LDAPConnection("ldap://ds.example.com:389", protocol=LDAP.LDAP_VERSION2)
    @test LDAP.get_protocol_version(ldap) == LDAP.LDAP_VERSION2

    # LDAP.simple_bind(ldap, "user", "pass")
    # LDAP.unbind(ldap)
end
