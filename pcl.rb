require 'formula'


class Pcl < Formula
  homepage 'http://www.pointclouds.org/'
  url 'http://downloads.sourceforge.net/project/pointclouds/1.6.0/PCL-1.6.0-Source.tar.bz2'
  sha1 '45a2e155d7faf5901abe609fd40d5f1659015e9e'

  head 'https://github.com/PointCloudLibrary/pcl.git'

  option 'examples'
  option 'with-qt', 'Build the Qt4 backend for examples'
  option 'with-openni', 'Enable support for OpenNI.'

  depends_on 'cmake' => :build
  depends_on 'pkg-config' => :build

  if build.head?
    depends_on 'boost'
  else
    depends_on 'boost149'

    fails_with :clang do
      cause "Compilation fails with clang"
    end
  end

  depends_on 'eigen'
  depends_on 'flann'
  depends_on 'cminpack'

  if build.with? 'qt'
    depends_on 'vtk' => 'qt'
  else
    depends_on 'vtk'
  end

  depends_on 'qhull'
  depends_on 'libusb'
  depends_on 'glew'
  depends_on 'totakke/openni/openni' if build.with? 'openni'

  def install
    args = std_cmake_args + %W[
      -DGLEW_INCLUDE_DIR=#{HOMEBREW_PREFIX}/include/GL
      -DCMAKE_BUILD_TYPE:STRING=Release
      -DBUILD_SHARED_LIBS:BOOL=TRUE
      -DBUILD_documentation:BOOL=OFF
      -DBUILD_TESTS:BOOL=FALSE
      -DBUILD_global_tests:BOOL=FALSE
      -DBUILD_apps:BOOL=ON
      -DBUILD_app_3d_rec_framework:BOOL=ON
      -DBUILD_app_in_hand_scanner:BOOL=ON
      -DBUILD_app_point_cloud_editor:BOOL=OFF
      -DBUILD_app_modeler:BOOL=ON
      -DBUILD_app_cloud_composer:BOOL=OFF
      -DBUILD_simulation:BOOL=OFF
    ]

    if !build.head?
      boost149_base = Formula.factory('boost149').installed_prefix
      boost149_include = File.join(boost149_base, 'include')
      args <<  "-DBoost_INCLUDE_DIR=#{boost149_include}"
    end

    if build.with? 'examples'
      args << "-DBUILD_examples:BOOL=ON"
    else
      args << "-DBUILD_examples:BOOL=OFF"
    end

    if build.with? 'openni'
      args << "-DOPENNI_INCLUDE_DIR=#{HOMEBREW_PREFIX}/include/ni"
    end

    args << '..'
    mkdir 'macbuild' do
      system 'cmake', *args
      system "make"
      system "make install"
    end
  end
end
