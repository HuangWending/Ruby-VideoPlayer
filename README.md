# Ruby-VideoPlayer
Ruby视频播放器
首先，确保已安装FFmpeg和GTK3库。然后，使用以下命令安装Ruby的相关库：
gem install gstreamer
gem install gtk3
1. 导入`gtk3`和`gstreamer`库，它们用于创建图形用户界面和处理视频播放。

require 'gtk3'
require 'gstreamer'

2. 我们创建了一个名为`VideoPlayer`的类，并在其构造函数中初始化窗口和各种界面元素。

class VideoPlayer
  def initialize
    @window = Gtk::Window.new('Video Player')
    @window.signal_connect('destroy') { Gtk.main_quit }
    @window.set_default_size(800, 600)

    @video_area = Gtk::DrawingArea.new
    @play_button = Gtk::Button.new(label: 'Play')
    @pause_button = Gtk::Button.new(label: 'Pause')
    @speed_slider = Gtk::Scale.new(:horizontal, 0.1, 2.0, 0.1)
    @volume_slider = Gtk::Scale.new(:horizontal, 0.0, 1.0, 0.1)

    # ...
  end

  # ...
end


3. 在构造函数中，我们还创建了用于显示视频的`Gtk::DrawingArea`，以及播放、暂停、速度和音量控制的按钮和滑块。

4. 在构造函数的后面，我们使用`Gtk::Box`将各个界面元素组合在一起，形成主要的用户界面。

@controls_box = Gtk::Box.new(:horizontal, 10)
@main_box = Gtk::Box.new(:vertical, 10)

# ...

@controls_box.pack_start(@play_button, expand: false, fill: false, padding: 0)
@controls_box.pack_start(@pause_button, expand: false, fill: false, padding: 0)
@controls_box.pack_start(@speed_slider, expand: false, fill: false, padding: 0)
@controls_box.pack_start(@volume_slider, expand: false, fill: false, padding: 0)

@main_box.pack_start(@video_area, expand: true, fill: true, padding: 0)
@main_box.pack_start(@controls_box, expand: false, fill: false, padding: 10)

@window.add(@main_box)
@window.show_all


现在我们进入setup_pipeline方法，在其中设置GStreamer管道和相关元素。
def setup_pipeline
  @pipeline = Gst::Pipeline.new
  @playbin

 = Gst::ElementFactory.make('playbin')

  @video_sink = Gst::ElementFactory.make('gtksink')
  @pipeline.add(@playbin, @video_sink)
  @playbin >> @video_sink

  bus = @pipeline.bus
  bus.add_watch(Gst::MessageType::EOS) { stop_playback }
  bus.add_watch(Gst::MessageType::ERROR) { |_bus, message| handle_error(message) }

  @pipeline.play
end


6. `setup_pipeline`方法创建了GStreamer管道，并使用`playbin`元素作为视频播放器。我们还创建了一个`gtksink`元素，用于在Gtk窗口中显示视频。通过将元素连接起来，并设置一些消息监听器，我们准备好播放视频。

7. `draw_video`方法用于在Gtk窗口的绘图区域中绘制视频帧。

def draw_video(cr)
  allocation = @video_area.allocation
  @video_sink.set_property('window', @video_area.window.handle)

  Gdk.cairo_set_source_pixbuf(cr, @video_area.pixbuf, 0, 0)
  cr.paint
  false
end


8. `toggle_playback`方法用于切换播放和暂停状态。

def toggle_playback
  if @pipeline.playing?
    @pipeline.pause
    @play_button.label = 'Play'
  else
    @pipeline.play
    @play_button.label = 'Pause'
  end
end


9. `update_speed`方法根据速度滑块的值更新播放速度。

def update_speed
  speed = @speed_slider.value
  @playbin.set_property('pitch', speed)
end


10. `update_volume`方法根据音量滑块的值更新音量大小。

def update_volume
  volume = @volume_slider.value
  @playbin.set_property('volume', volume)
end


11. `stop_playback`方法用于停止视频播放。

def stop_playback
  @pipeline.stop
  @play_button.label = 'Play'
end


12. `handle_error`方法用于处理播放过程中的错误消息。

def handle_error(message)
  error = message.parse_error
  puts "Error: #{error.message}"
end


13. 最后，我们创建一个`VideoPlayer`对象并运行应用程序的主事件循环。

player = VideoPlayer.new
player.run
