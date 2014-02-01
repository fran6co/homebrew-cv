require 'formula'


class Pcl < Formula
  homepage 'http://www.pointclouds.org/'
  url 'https://github.com/PointCloudLibrary/pcl/archive/pcl-1.7.1.zip'
  sha1 '9a21d36980e9b67ef6d43fbb3dfdc4b4291acec2'
  version "1.7.1"

  head 'https://github.com/PointCloudLibrary/pcl.git'

  option 'with-examples', 'Build pcl examples.'
  option 'with-tests', 'Build pcl tests.'
  option 'without-tools', 'Build without tools.'
  option 'without-apps', 'Build without apps.'
  option 'without-qvtk', 'Build without qvtk support.'

  depends_on 'cmake' => :build
  depends_on 'pkg-config' => :build

  depends_on 'boost'
  depends_on 'eigen'
  depends_on 'flann'
  depends_on 'cminpack'

  # PCL doesn't support qhull 2012 yet
  depends_on 'qhull2011'
  depends_on 'libusb'
  depends_on 'glew'
  depends_on 'qt' => :recommended
  if build.with? 'qvtk'
    depends_on 'homebrew/versions/vtk5' => [:recommended,'with-qt']
  else
    depends_on 'homebrew/versions/vtk5' => :recommended
  end
  depends_on 'homebrew/science/openni' => :optional

  def patches
    # wrong opengl headers
    if !build.head?
    	fix_gl_headers =  [
	        "apps/in_hand_scanner/src/opengl_viewer.cpp",
	        "surface/include/pcl/surface/3rdparty/opennurbs/opennurbs_gl.h",
        ]

    	fix_glu_headers =  fix_gl_headers + [
	        "apps/point_cloud_editor/src/cloudEditorWidget.cpp",
        ]
        
        inreplace fix_glu_headers, '<GL/glu.h>', '<OpenGL/glu.h>'
        inreplace fix_gl_headers, '<GL/gl.h>', '<OpenGL/gl.h>'
    end
    fixes = []
    if build.head?
        fixes = [
           "https://github.com/PointCloudLibrary/pcl/pull/486.patch",
        ]
    end
    
    # fixes GLEW linking and qhull2011
    [DATA] + fixes
  end

  def install
    raise 'PCL currently requires --HEAD on Mavericks' if MacOS.version == :mavericks and not build.head?

    qhull2011_base = Formula.factory('qhull2011').installed_prefix

    args = std_cmake_args + %W[
      -DGLEW_INCLUDE_DIR=#{HOMEBREW_PREFIX}/include/GL
      -DQHULL_ROOT=#{qhull2011_base}
      -DBUILD_SHARED_LIBS:BOOL=ON
      -DBUILD_simulation:BOOL=AUTO_OFF
      -DBUILD_outofcore:BOOL=AUTO_OFF
      -DBUILD_people:BOOL=AUTO_OFF
    ]

    if build.with? 'apps'
      args = args + %W[
        -DBUILD_apps=AUTO_OFF
        -DBUILD_apps_3d_rec_framework=AUTO_OFF
        -DBUILD_apps_cloud_composer:BOOL=OFF
        -DBUILD_apps_in_hand_scanner=AUTO_OFF
        -DBUILD_apps_modeler=AUTO_OFF
        -DBUILD_apps_optronic_viewer=AUTO_OFF
        -DBUILD_apps_point_cloud_editor=AUTO_OFF
      ]
    else
      args << "-DBUILD_apps:BOOL=OFF"
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

    if build.without? 'vtk5'
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

