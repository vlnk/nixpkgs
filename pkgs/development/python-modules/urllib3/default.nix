{ lib
, stdenv
, brotli
, buildPythonPackage
, certifi
, cryptography
, dateutil
, fetchPypi
, idna
, mock
, pyopenssl
, pysocks
, pytest-freezegun
, pytest-timeout
, pytestCheckHook
, pythonOlder
, tornado
, trustme
}:

buildPythonPackage rec {
  pname = "urllib3";
  version = "1.26.3";
  disabled = pythonOlder "3.6";

  src = fetchPypi {
    inherit pname version;
    sha256 = "de3eedaad74a2683334e282005cd8d7f22f4d55fa690a2a1020a416cb0a47e73";
  };

  propagatedBuildInputs = [
    brotli
    certifi
    cryptography
    idna
    pyopenssl
    pysocks
  ];

  checkInputs = [
    dateutil
    mock
    pytest-freezegun
    pytest-timeout
    pytestCheckHook
    tornado
    trustme
  ];

  disabledTests = if stdenv.hostPlatform.isAarch64 then
    [
      "test_connection_closed_on_read_timeout_preload_false"
      "test_ssl_failed_fingerprint_verification"
      ]
  else
    null;

  pythonImportsCheck = [ "urllib3" ];

  meta = with lib; {
    description = "Powerful, sanity-friendly HTTP client for Python";
    homepage = "https://github.com/shazow/urllib3";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
