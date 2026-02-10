#include "my_application.h"

int main(int argc, char** argv) {
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_argument(project, argc, argv);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  g_autoptr(FlWindow) window =
      fl_window_new(FL_PROJECT(project), GTK_WIDGET(view));
  gtk_widget_show(GTK_WIDGET(window));

  gtk_main();
  return 0;
}
