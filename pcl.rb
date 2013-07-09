require 'formula'


class Pcl < Formula
  homepage 'http://www.pointclouds.org/'
  url 'http://downloads.sourceforge.net/project/pointclouds/1.6.0/PCL-1.6.0-Source.tar.bz2'
  sha1 '45a2e155d7faf5901abe609fd40d5f1659015e9e'

  head 'https://github.com/PointCloudLibrary/pcl.git'

  option 'with-examples', 'Build pcl examples.'
  if build.head?
    option 'with-tests', 'Build pcl tests.'
  end
  option 'with-qt', 'Enable support for Qt4 backend.'
  option 'with-openni', 'Enable support for OpenNI.'
  option 'without-tools', 'Build without tools.'
  option 'without-apps', 'Build without apps.'

  depends_on 'cmake' => :build
  depends_on 'pkg-config' => :build

  def patches
    fixes = []

    if build.head?
      # wrong opengl headers
      fix_glut_headers = [
	"gpu/kinfu/tools/kinfu_app_sim.cpp",
	"gpu/kinfu_large_scale/tools/kinfu_app_sim.cpp",
	"simulation/tools/sim_test_performance.cpp",
	"simulation/tools/sim_test_simple.cpp",
	"simulation/tools/simulation_io.hpp",
      ]
      fix_glu_headers = fix_glut_headers + [
	"apps/in_hand_scanner/src/opengl_viewer.cpp",
	"apps/point_cloud_editor/src/cloud.cpp",
	"apps/point_cloud_editor/src/cloudEditorWidget.cpp",
	"simulation/include/pcl/simulation/model.h",
	"simulation/include/pcl/simulation/range_likelihood.h",
	"simulation/src/range_likelihood.cpp",
	"surface/include/pcl/surface/3rdparty/opennurbs/opennurbs_gl.h",
      ]
      fix_gl_headers = fix_glu_headers + [
	"apps/point_cloud_editor/include/pcl/apps/point_cloud_editor/select2DTool.h",
	"apps/point_cloud_editor/src/select1DTool.cpp",
	"simulation/include/pcl/simulation/sum_reduce.h",
	"simulation/tools/sim_viewer.cpp",
      ]
      inreplace fix_glu_headers, '<GL/glu.h>', '<OpenGL/glu.h>'
      inreplace fix_glut_headers, '<GL/glut.h>', '<GLUT/glut.h>'
      inreplace fix_gl_headers, '<GL/gl.h>', '<OpenGL/gl.h>'
    end
    # fixes GLEW linking and qhull2011
    [DATA] + fixes
  end

  if build.head?
    depends_on 'boost'
  else
    depends_on 'boost149'

    fails_with :clang do
      cause "Compilation fails with clang on 1.6.0"
    end
  end

  depends_on 'eigen'
  depends_on 'flann'
  depends_on 'cminpack'
  
  if build.with? 'qt'
    depends_on 'vtk' => [:recommended,'qt']
    depends_on 'sip'
    depends_on 'pyqt'
  else
    depends_on 'vtk' => :recommended
  end

  # PCL doesn't support qhull 2012 yet
  depends_on 'qhull2011'
  depends_on 'libusb'
  depends_on 'glew'
  depends_on 'totakke/openni/openni' if build.with? 'openni'

  def install
    qhull2011_base = Formula.factory('qhull2011').installed_prefix

    args = std_cmake_args + %W[
      -DGLEW_INCLUDE_DIR=#{HOMEBREW_PREFIX}/include/GL
      -DQHULL_ROOT=#{qhull2011_base}
      -DCMAKE_BUILD_TYPE:STRING=Release
      -DBUILD_SHARED_LIBS:BOOL=ON
      -DBUILD_simulation:BOOL=ON
      -DBUILD_outofcore:BOOL=ON
      -DBUILD_people:BOOL=ON
    ]

    if build.with? 'apps'
      args = args + %W[
        -DBUILD_apps:BOOL=ON
        -DBUILD_app_3d_rec_framework:BOOL=ON
        -DBUILD_app_cloud_composer:BOOL=OFF
      ]

      if build.with? 'qt'
        args << "-DBUILD_app_modeler:BOOL=ON"
        args << "-DBUILD_app_in_hand_scanner:BOOL=ON" if build.with? 'openni'
        args << "-DBUILD_app_point_cloud_editor:BOOL=ON"
      end
      
    else
      args << "-DBUILD_apps:BOOL=OFF"
    end

    if !build.head?
      boost149_base = Formula.factory('boost149').installed_prefix
      boost149_include = File.join(boost149_base, 'include')
      args <<  "-DBoost_INCLUDE_DIR=#{boost149_include}"
    end

    if build.without? 'tools'
      args << "-DBUILD_tools:BOOL=OFF"
    end

    if build.with? 'examples'
      args << "-DBUILD_examples:BOOL=ON"
    else
      args << "-DBUILD_examples:BOOL=OFF"
    end

    if build.with? 'tests'
      args << "-DBUILD_global_tests:BOOL=ON"
    else
      args << "-DBUILD_global_tests:BOOL=OFF"
    end

    if build.with? 'openni'
      args << "-DOPENNI_INCLUDE_DIR=#{HOMEBREW_PREFIX}/include/ni"
    else
      args << "-DCMAKE_DISABLE_FIND_PACKAGE_OpenNI:BOOL=TRUE"
    end

    if build.without? 'qt'
      args << "-DCMAKE_DISABLE_FIND_PACKAGE_Qt4:BOOL=TRUE"
    end

    if build.without? 'vtk'
      args << "-DCMAKE_DISABLE_FIND_PACKAGE_VTK:BOOL=TRUE"
    end

    args << '..'
    mkdir 'macbuild' do
      system 'cmake', *args
      system "make"
      system "make install"
      if build.with? 'test'
        system 'make test'
      end
    end
  end
end
__END__
diff --git a/cmake/Modules/FindQhull.cmake b/cmake/Modules/FindQhull.cmake
index f5fd269..2d16436 100644
--- a/cmake/Modules/FindQhull.cmake
+++ b/cmake/Modules/FindQhull.cmake
@@ -47,12 +47,14 @@ find_library(QHULL_LIBRARY
              NAMES ${QHULL_RELEASE_NAME}
              HINTS "${QHULL_ROOT}" "$ENV{QHULL_ROOT}"
              PATHS "$ENV{PROGRAMFILES}/QHull" "$ENV{PROGRAMW6432}/QHull" 
+             NO_DEFAULT_PATH
              PATH_SUFFIXES project build bin lib)
 
 find_library(QHULL_LIBRARY_DEBUG 
              NAMES ${QHULL_DEBUG_NAME} ${QHULL_RELEASE_NAME}
              HINTS "${QHULL_ROOT}" "$ENV{QHULL_ROOT}"
              PATHS "$ENV{PROGRAMFILES}/QHull" "$ENV{PROGRAMW6432}/QHull" 
+             NO_DEFAULT_PATH
              PATH_SUFFIXES project build bin lib)
 
 if(NOT QHULL_LIBRARY_DEBUG) 
diff --git a/cmake/Modules/FindGLEW.cmake b/cmake/Modules/FindGLEW.cmake
index c45585c..42e6c39 100644
--- a/cmake/Modules/FindGLEW.cmake
+++ b/cmake/Modules/FindGLEW.cmake
@@ -46,7 +46,7 @@ ELSE (WIN32)
       /System/Library/Frameworks/GLEW.framework/Versions/A/Headers
       ${OPENGL_LIBRARY_DIR}
     )
-    SET(GLEW_GLEW_LIBRARY "-framework GLEW" CACHE STRING "GLEW library for OSX")
+    FIND_LIBRARY( GLEW_GLEW_LIBRARY GLEW)
     SET(GLEW_cocoa_LIBRARY "-framework Cocoa" CACHE STRING "Cocoa framework for OSX")
   ELSE (APPLE)

