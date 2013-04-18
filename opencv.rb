require 'formula'

def which_python
  "python" + `python -c 'import sys;print(sys.version[:3])'`.strip
end

def site_package_dir
  "lib/#{which_python}/site-packages"
end

class Opencv < Formula
  homepage 'http://opencv.org/'
  url 'http://sourceforge.net/projects/opencvlibrary/files/opencv-unix/2.4.4/OpenCV-2.4.4a.tar.bz2'
  sha1 '6e518c0274a8392c0c98d18ef0ef754b9c596aca'

  env :std # to find python

  option '32-bit'
  option 'with-qt',  'Build the Qt4 backend to HighGUI'
  option 'with-tbb', 'Enable parallel code in OpenCV using Intel TBB'
  option 'with-opencl', 'Enable gpu code in OpenCV using OpenCL'
  option 'with-ffmpeg', 'Enable ffmpeg video input'
  option 'with-openni', 'Enable support for OpenNI.'

  depends_on 'cmake' => :build
  depends_on 'pkg-config' => :build
  depends_on 'numpy' => :python

  depends_on 'eigen'   => :optional
  depends_on 'libtiff' => :optional
  depends_on 'jasper'  => :optional
  depends_on 'tbb'     => :optional
  depends_on 'qt'      => :optional
  depends_on 'ffmpeg'  => :optional
  depends_on 'openexr' => :optional
  depends_on 'totakke/openni/openni' if build.with? 'openni'
  depends_on :libpng

  # Can also depend on ffmpeg, but this pulls in a lot of extra stuff that
  # you don't need unless you're doing video analysis, and some of it isn't
  # in Homebrew anyway. Will depend on openexr if it's installed.

  # Fix non-ASCII characters breaking in Java 1.7
  # https://github.com/Itseez/opencv/pull/718
  def patches; DATA; end

  def install
    args = std_cmake_args + %w[
      -DCMAKE_OSX_DEPLOYMENT_TARGET=
      -DWITH_CUDA=OFF
      -DBUILD_ZLIB=OFF
      -DBUILD_TIFF=OFF
      -DBUILD_PNG=OFF
      -DBUILD_JPEG=OFF
      -DBUILD_JASPER=OFF
      -DBUILD_OPENEXR=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_PERF_TESTS=OFF
      -DENABLE_PRECOMPILED_HEADERS=ON
    ]
    if build.build_32_bit?
      args << "-DCMAKE_OSX_ARCHITECTURES=i386"
      args << "-DOPENCV_EXTRA_C_FLAGS='-arch i386 -m32'"
      args << "-DOPENCV_EXTRA_CXX_FLAGS='-arch i386 -m32'"
    end
    args << '-DWITH_QT=ON' if build.with? 'qt'
    args << '-DWITH_TBB=ON' if build.with? 'tbb'
    args << '-DWITH_OPENCL=ON' if build.with? 'opencl'
    args << '-DWITH_FFMPEG=ON' if build.with? 'ffmpeg'
    args << '-DWITH_OPENNI=ON' if build.with? 'openni'

    # Check for SIMD code support
    if ENV.compiler == :clang
      # not sure how to check SSSE3 hardware support but this should be safe
      args << '-DENABLE_SSSE3=ON' << '-DENABLE_SSE41=ON' if (Hardware::CPU.family == :penryn or Hardware::CPU.sse4?) and ENV.compiler == :clang
      args << '-DENABLE_SSE42=ON' if Hardware::CPU.sse4? and ENV.compiler == :clang
      args << '-DENABLE_AVX=ON' if Hardware::CPU.avx? and ENV.compiler == :clang
    end

    # The CMake `FindPythonLibs` Module is dumber than a bag of hammers when
    # more than one python installation is available---for example, it clings
    # to the Header folder of the system Python Framework like a drowning
    # sailor.
    #
    # This code was cribbed from the VTK formula and uses the output to
    # `python-config` to do the job FindPythonLibs should be doing in the first
    # place.
    python_prefix = `python-config --prefix`.strip
    # Python is actually a library. The libpythonX.Y.dylib points to this lib, too.
    if File.exist? "#{python_prefix}/Python"
      # Python was compiled with --framework:
      args << "-DPYTHON_LIBRARY='#{python_prefix}/Python'"
      if !MacOS::CLT.installed? and python_prefix.start_with? '/System/Library'
        # For Xcode-only systems, the headers of system's python are inside of Xcode
        args << "-DPYTHON_INCLUDE_DIR='#{MacOS.sdk_path}/System/Library/Frameworks/Python.framework/Versions/2.7/Headers'"
      else
        args << "-DPYTHON_INCLUDE_DIR='#{python_prefix}/Headers'"
      end
    else
      python_lib = "#{python_prefix}/lib/lib#{which_python}"
      if File.exists? "#{python_lib}.a"
        args << "-DPYTHON_LIBRARY='#{python_lib}.a'"
      else
        args << "-DPYTHON_LIBRARY='#{python_lib}.dylib'"
      end
      args << "-DPYTHON_INCLUDE_DIR='#{python_prefix}/include/#{which_python}'"
    end
    args << "-DPYTHON_PACKAGES_PATH='#{lib}/#{which_python}/site-packages'"

    args << '..'
    mkdir 'macbuild' do
      system 'cmake', *args
      system "make"
      system "make install"
    end
  end

  def caveats; <<-EOS.undent
    The OpenCV Python module will not work until you edit your PYTHONPATH like so:
      export PYTHONPATH="#{HOMEBREW_PREFIX}/#{site_package_dir}:$PYTHONPATH"

    To make this permanent, put it in your shell's profile (e.g. ~/.profile).
    EOS
  end
end

# If openni was installed using homebrew, look for it on the proper path
__END__
diff --git a/cmake/OpenCVFindOpenNI.cmake b/cmake/OpenCVFindOpenNI.cmake
index 7541868..f1455e8 100644
--- a/cmake/OpenCVFindOpenNI.cmake
+++ b/cmake/OpenCVFindOpenNI.cmake
@@ -26,8 +26,8 @@ if(WIN32)
         find_library(OPENNI_LIBRARY "OpenNI64" PATHS $ENV{OPEN_NI_LIB64} DOC "OpenNI library")
     endif()
 elseif(UNIX OR APPLE)
-    find_file(OPENNI_INCLUDES "XnCppWrapper.h" PATHS "/usr/include/ni" "/usr/include/openni" DOC "OpenNI c++ interface header")
-    find_library(OPENNI_LIBRARY "OpenNI" PATHS "/usr/lib" DOC "OpenNI library")
+    find_file(OPENNI_INCLUDES "XnCppWrapper.h" PATHS "#{HOMEBREW_PREFIX}/include/ni" "/usr/include/ni" "/usr/include/openni" DOC "OpenNI c++ interface header")
+    find_library(OPENNI_LIBRARY "OpenNI" PATHS "#{HOMEBREW_PREFIX}/lib" "/usr/lib" DOC "OpenNI library")
 endif()

 if(OPENNI_LIBRARY AND OPENNI_INCLUDES)
diff --git a/modules/java/build.xml.in b/modules/java/build.xml.in
index 98ba2e3..c1c1854 100644
--- a/modules/java/build.xml.in
+++ b/modules/java/build.xml.in
@@ -8,8 +8,9 @@
     <!-- http://stackoverflow.com/questions/3584968/ant-how-to-compile-jar-that-includes-source-attachment -->
     <javac sourcepath="" srcdir="src" destdir="src" debug="on" includeantruntime="false" >
       <include name="**/*.java"/>
+      <compilerarg line="-encoding utf-8"/>
     </javac>
 
     <jar basedir="src" destfile="bin/@JAR_NAME@"/>
   </target>
-</project>
\ No newline at end of file
+</project>
