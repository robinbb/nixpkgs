{ stdenv, fetchurl, scons, boost, gperftools, pcre, snappy
, zlib, libyamlcpp, sasl, openssl, libpcap, wiredtiger
}:

# Note:
# The command line tools are written in Go as part of a different package (mongodb-tools)

with stdenv.lib;

let version = "3.2.1";
    system-libraries = [
      "pcre"
      #"asio" -- XXX use package?
      #"wiredtiger"
      "boost"
      "snappy"
      "zlib"
      #"valgrind" -- mongodb only requires valgrind.h, which is vendored in the source.
      #"stemmer"  -- not nice to package yet (no versioning, no makefile, no shared libs).
      "yaml"
    ] ++ optionals stdenv.isLinux [ "tcmalloc" ];
    buildInputs = [
      sasl boost gperftools pcre snappy
      zlib libyamlcpp sasl openssl libpcap
    ]; # ++ optional stdenv.is64bit wiredtiger;

    other-args = concatStringsSep " " ([
      "--ssl"
      #"--rocksdb" # Don't have this packaged yet
      "--wiredtiger=${if stdenv.is64bit then "on" else "off"}"
      "--js-engine=mozjs"
      "--use-sasl-client"
      "--disable-warnings-as-errors"
      "VARIANT_DIR=nixos" # Needed so we don't produce argument lists that are too long for gcc / ld
      "CC=$CC"
      "CXX=$CXX"
      "CCFLAGS=\"${concatStringsSep " " (map (input: "-I${input}/include") buildInputs)}\""
      "LINKFLAGS=\"${concatStringsSep " " (map (input: "-L${input}/lib") buildInputs)}\""
    ] ++ map (lib: "--use-system-${lib}") system-libraries);

in stdenv.mkDerivation rec {
  name = "mongodb-${version}";

  src = fetchurl {
    url = "http://downloads.mongodb.org/src/mongodb-src-r${version}.tar.gz";
    sha256 = "059gskly8maj2c9iy46gccx7a9ya522pl5aaxl5vss5bllxilhsh";
  };

  nativeBuildInputs = [ scons ];
  inherit buildInputs;

  # When not building with the system valgrind, the build should use the
  # vendored header file - regardless of whether or not we're using the system
  # tcmalloc - so we need to lift the include path manipulation out of the
  # conditional.
  patches = [ ./valgrind-include.patch ];

  postPatch = ''
    # fix environment variable reading
    substituteInPlace SConstruct \
        --replace "env = Environment(" "env = Environment(ENV = os.environ,"
  '' + stdenv.lib.optionalString stdenv.isDarwin ''

    substituteInPlace src/third_party/s2/s1angle.cc --replace drem remainder
    substituteInPlace src/third_party/s2/s1interval.cc --replace drem remainder
    substituteInPlace src/third_party/s2/s2cap.cc --replace drem remainder
    substituteInPlace src/third_party/s2/s2latlng.cc --replace drem remainder
    substituteInPlace src/third_party/s2/s2latlngrect.cc --replace drem remainder
  '';

  buildPhase = ''
    scons -j $NIX_BUILD_CORES core --release ${other-args}
  '';

  installPhase = ''
    mkdir -p $out/lib
    scons -j $NIX_BUILD_CORES install --release --prefix=$out ${other-args}
  '';

  enableParallelBuilding = true;

  meta = {
    description = "a scalable, high-performance, open source NoSQL database";
    homepage = http://www.mongodb.org;
    license = licenses.agpl3;

    maintainers = with maintainers; [ bluescreen303 offline wkennington cstrahan ];
    platforms = platforms.unix;
  };
}
