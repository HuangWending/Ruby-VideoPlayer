require 'gtk3'
require 'gstreamer'

class VideoPlayer
  def initialize
    @window = Gtk::Window.new('Video Player')
    @window.signal_connect('destroy') { Gtk.main_quit }
    @window.set_default_size(800, 600)

    @video_area = Gtk::DrawingArea.new
    @video_area.signal_connect('realize') { setup_pipeline }
    @video_area.signal_connect('draw') { |_widget, cr| draw_video(cr) }

    @play_button = Gtk::Button.new(label: 'Play')
    @play_button.signal_connect('clicked') { toggle_playback }

    @pause_button = Gtk::Button.new(label: 'Pause')
    @pause_button.signal_connect('clicked') { toggle_playback }

    @speed_slider = Gtk::Scale.new(:horizontal, 0.1, 2.0, 0.1)
    @speed_slider.signal_connect('value-changed') { update_speed }

    @volume_slider = Gtk::Scale.new(:horizontal, 0.0, 1.0, 0.1)
    @volume_slider.signal_connect('value-changed') { update_volume }

    @controls_box = Gtk::Box.new(:horizontal, 10)
    @controls_box.pack_start(@play_button, expand: false, fill: false, padding: 0)
    @controls_box.pack_start(@pause_button, expand: false, fill: false, padding: 0)
    @controls_box.pack_start(@speed_slider, expand: false, fill: false, padding: 0)
    @controls_box.pack_start(@volume_slider, expand: false, fill: false, padding: 0)

    @main_box = Gtk::Box.new(:vertical, 10)
    @main_box.pack_start(@video_area, expand: true, fill: true, padding: 0)
    @main_box.pack_start(@controls_box, expand: false, fill: false, padding: 10)

    @window.add(@main_box)
    @window.show_all
  end

  def setup_pipeline
    @pipeline = Gst::Pipeline.new
    @playbin = Gst::ElementFactory.make('playbin')

    @video_sink = Gst::ElementFactory.make('gtksink')
    @video_sink.signal_connect('client-draw') { |_widget, overlay| overlay.expose }

    @pipeline.add(@playbin, @video_sink)
    @playbin >> @video_sink

    bus = @pipeline.bus
    bus.add_watch(Gst::MessageType::EOS) { stop_playback }
    bus.add_watch(Gst::MessageType::ERROR) { |_bus, message| handle_error(message) }

    @pipeline.play
  end

  def draw_video(cr)
    allocation = @video_area.allocation
    @video_sink.set_property('window', @video_area.window.handle)

    Gdk.cairo_set_source_pixbuf(cr, @video_area.pixbuf, 0, 0)
    cr.paint
    false
  end

  def toggle_playback
    if @pipeline.playing?
      @pipeline.pause
      @play_button.label = 'Play'
    else
      @pipeline.play
      @play_button.label = 'Pause'
    end
  end

  def update_speed
    speed = @speed_slider.value
    @playbin.set_property('pitch', speed)
  end

  def update_volume
    volume = @volume_slider.value
    @playbin.set_property('volume', volume)
  end

  def stop_playback
    @pipeline.stop
    @play_button.label = 'Play'
  end

  def handle_error(message)
    error = message.parse_error
    puts "Error: #{error.message}"
  end

  def run
    Gtk.main
  end
end

player = VideoPlayer.new
player.run
