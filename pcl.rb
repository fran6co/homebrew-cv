require 'formula'


class Pcl < Formula
  homepage 'http://www.pointclouds.org/'
  url 'http://downloads.sourceforge.net/project/pointclouds/1.6.0/PCL-1.6.0-Source.tar.bz2'
  sha1 '45a2e155d7faf5901abe609fd40d5f1659015e9e'

  head 'https://github.com/PointCloudLibrary/pcl.git', :revision => '25cd0bd12ca79710c8e3aadac669bbea635e73aa'

  option 'examples'
  option 'with-qt', 'Build the Qt4 backend for examples'
  option 'with-openni', 'Enable support for OpenNI.'

  depends_on 'cmake' => :build
  depends_on 'pkg-config' => :build

  def patches
    # fixes simulation compilation with opengl
    DATA
  end

  if build.head?
    version '1.7.0'
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
__END__
diff --git a/simulation/include/pcl/simulation/model.h b/simulation/include/pcl/simulation/model.h
index ef599cd..d262a2f 100644
--- a/simulation/include/pcl/simulation/model.h
+++ b/simulation/include/pcl/simulation/model.h
@@ -6,8 +6,8 @@
 # include <windows.h>
 #endif
 #include <GL/glew.h>
-#include <GL/gl.h>
-#include <GL/glu.h>
+#include <OpenGL/gl.h>
+#include <OpenGL/glu.h>
 
 #include <boost/shared_ptr.hpp>
 #include <pcl/pcl_macros.h>
diff --git a/simulation/include/pcl/simulation/range_likelihood.h b/simulation/include/pcl/simulation/range_likelihood.h
index 238b3f9..5c41ec7 100644
--- a/simulation/include/pcl/simulation/range_likelihood.h
+++ b/simulation/include/pcl/simulation/range_likelihood.h
@@ -2,8 +2,8 @@
 #define PCL_RANGE_LIKELIHOOD
 
 #include <GL/glew.h>
-#include <GL/gl.h>
-#include <GL/glu.h>
+#include <OpenGL/gl.h>
+#include <OpenGL/glu.h>
 
 #include <boost/random/linear_congruential.hpp>
 #include <boost/random/normal_distribution.hpp>
diff --git a/simulation/include/pcl/simulation/sum_reduce.h b/simulation/include/pcl/simulation/sum_reduce.h
index e81a8ff..531f064 100644
--- a/simulation/include/pcl/simulation/sum_reduce.h
+++ b/simulation/include/pcl/simulation/sum_reduce.h
@@ -9,7 +9,7 @@
 #define PCL_SIMULATION_SUM_REDUCE
 
 #include <GL/glew.h>
-#include <GL/gl.h>
+#include <OpenGL/gl.h>
 #include <pcl/simulation/glsl_shader.h>
 #include <pcl/simulation/model.h>
 
diff --git a/simulation/src/range_likelihood.cpp b/simulation/src/range_likelihood.cpp
index ee7a0fb..b981970 100644
--- a/simulation/src/range_likelihood.cpp
+++ b/simulation/src/range_likelihood.cpp
@@ -1,6 +1,6 @@
 #include <GL/glew.h>
-#include <GL/gl.h>
-#include <GL/glu.h>
+#include <OpenGL/gl.h>
+#include <OpenGL/glu.h>
 
 #include <pcl/common/time.h>
 #include <pcl/simulation/range_likelihood.h>
diff --git a/simulation/tools/sim_test_performance.cpp b/simulation/tools/sim_test_performance.cpp
index e9dab3f..7d425ba 100644
--- a/simulation/tools/sim_test_performance.cpp
+++ b/simulation/tools/sim_test_performance.cpp
@@ -14,9 +14,9 @@
 # include <windows.h>
 #endif
 #include <GL/glew.h>
-#include <GL/gl.h>
-#include <GL/glu.h>
-#include <GL/glut.h>
+#include <OpenGL/gl.h>
+#include <OpenGL/glu.h>
+#include <GLUT/glut.h>
 #include <pcl/io/pcd_io.h>
 #include <pcl/point_types.h>
 
diff --git a/simulation/tools/sim_test_simple.cpp b/simulation/tools/sim_test_simple.cpp
index a8e731a..1c3be8e 100644
--- a/simulation/tools/sim_test_simple.cpp
+++ b/simulation/tools/sim_test_simple.cpp
@@ -25,9 +25,9 @@
 # include <windows.h>
 #endif
 #include <GL/glew.h>
-#include <GL/gl.h>
-#include <GL/glu.h>
-#include <GL/glut.h>
+#include <OpenGL/gl.h>
+#include <OpenGL/glu.h>
+#include <GLUT/glut.h>
 #include <pcl/io/pcd_io.h>
 #include <pcl/point_types.h>
 
diff --git a/simulation/tools/sim_viewer.cpp b/simulation/tools/sim_viewer.cpp
index da4e625..fbdd3a5 100644
--- a/simulation/tools/sim_viewer.cpp
+++ b/simulation/tools/sim_viewer.cpp
@@ -46,7 +46,7 @@
 # include <windows.h>
 #endif
 #include <GL/glew.h>
-#include <GL/gl.h>
+#include <OpenGL/gl.h>
 
 #include <pcl/io/pcd_io.h>
 #include <pcl/point_types.h>
diff --git a/simulation/tools/simulation_io.hpp b/simulation/tools/simulation_io.hpp
index 634c89b..93797b1 100644
--- a/simulation/tools/simulation_io.hpp
+++ b/simulation/tools/simulation_io.hpp
@@ -4,9 +4,9 @@
 #include <boost/shared_ptr.hpp>
 
 #include <GL/glew.h>
-#include <GL/gl.h>
-#include <GL/glu.h>
-#include <GL/glut.h>
+#include <OpenGL/gl.h>
+#include <OpenGL/glu.h>
+#include <GLUT/glut.h>
 
 // define the following in order to eliminate the deprecated headers warning
 #define VTK_EXCLUDE_STRSTREAM_HEADERS
