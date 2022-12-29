import 'dart:typed_data';

import '../color/channel.dart';
import '../color/channel_iterator.dart';
import '../color/color.dart';
import '../color/format.dart';
import '../util/color_util.dart';
import '../util/float16.dart';
import 'image.dart';
import 'image_data_float16.dart';
import 'palette.dart';
import 'pixel.dart';

class PixelFloat16 extends Iterable<num> implements Pixel {
  int _x;
  int _y;
  int _index;
  final ImageDataFloat16 image;

  PixelFloat16.imageData(this.image)
      : _x = -1
      , _y = 0
      , _index = -image.numChannels;

  PixelFloat16.image(Image image)
      : _x = -1
      , _y = 0
      , _index = -image.numChannels
      , image = image.data is ImageDataFloat16 ? image.data as ImageDataFloat16
          : ImageDataFloat16(0, 0, 0);

  PixelFloat16.from(PixelFloat16 other)
      : _x = other._x
      , _y = other._y
      , _index = other._index
      , image = other.image;

  PixelFloat16 clone() => PixelFloat16.from(this);

  Format get format => Format.float16;
  int get length => image.numChannels;
  int get numChannels => image.numChannels;
  bool get hasPalette => image.hasPalette;
  Palette? get palette => null;
  int get width => image.width;
  int get height => image.height;
  Uint16List get data => image.data;
  num get maxChannelValue => image.maxChannelValue;
  num get maxIndexValue => image.maxIndexValue;
  bool get isLdrFormat => image.isLdrFormat;
  bool get isHdrFormat => image.isHdrFormat;

  bool get isValid => x >= 0 && x < (image.width - 1) &&
      y >= 0 && y < (image.height - 1);

  int get x => _x;
  int get y => _y;

  /// The normalized x coordinate of the pixel, in the range \[0, 1\].
  num get xNormalized => width > 1 ? x / (width - 1) : 0;

  /// The normalized y coordinate of the pixel, in the range \[0, 1\].
  num get yNormalized => height > 1 ? _y / (height - 1) : 0;

  /// Set the normalized coordinates of the pixel, in the range \[0, 1\].
  void setPositionNormalized(num x, num y) =>
      setPosition((x * (width - 1)).floor(), (y * (height - 1)).floor());

  void setPosition(int x, int y) {
    this._x = x;
    this._y = y;
    _index = _y * image.width * image.numChannels + (_x * image.numChannels);
  }

  Pixel get current => this;

  bool moveNext() {
    _x++;
    if (_x == width) {
      _x = 0;
      _y++;
      if (_y == height) {
        return false;
      }
    }
    _index += numChannels;
    return _index < image.data.length;
  }

  num operator[](int i) =>
      i < numChannels ? Float16.float16ToDouble(data[_index + i]) : 0;

  void operator[]=(int i, num value) {
    if (i < image.numChannels) {
      final d = value.toDouble();
      data[_index + i] = Float16.doubleToFloat16(d);
    }
  }

  num get index => r;
  void set index(num i) => r = i;

  num get r => numChannels > 0 ? Float16.float16ToDouble(data[_index + 0]) : 0;

  void set r(num r) {
    if (numChannels > 0) {
      final d = r.toDouble();
      data[_index] = Float16.doubleToFloat16(d);
    }
  }

  num get g => numChannels > 1 ? Float16.float16ToDouble(data[_index + 1]) : 0;

  void set g(num g) {
    if (numChannels > 1) {
      final d = g.toDouble();
      data[_index + 1] = Float16.doubleToFloat16(d);
    }
  }

  num get b => numChannels > 2 ? Float16.float16ToDouble(data[_index + 2]) : 0;

  void set b(num b) {
    if (numChannels > 2) {
      final d = b.toDouble();
      data[_index + 2] = Float16.doubleToFloat16(d);
    }
  }

  num get a => numChannels > 3 ? Float16.float16ToDouble(data[_index + 3]) : 0;

  void set a(num a) {
    if (numChannels > 3) {
      final d = g.toDouble();
      data[_index + 3] = Float16.doubleToFloat16(d);
    }
  }

  num get rNormalized => r / maxChannelValue;
  void set rNormalized(num v) => r = v * maxChannelValue;

  num get gNormalized => g / maxChannelValue;
  void set gNormalized(num v) => g = v * maxChannelValue;

  num get bNormalized => b / maxChannelValue;
  void set bNormalized(num v) => b = v * maxChannelValue;

  num get aNormalized => a / maxChannelValue;
  void set aNormalized(num v) => a = v * maxChannelValue;

  num get luminance => getLuminance(this);
  num get luminanceNormalized => getLuminanceNormalized(this);

  num getChannel(Channel channel) => channel == Channel.luminance ?
      luminance : channel.index < numChannels
      ? Float16.float16ToDouble(data[_index + channel.index])
      : 0;

  num getChannelNormalized(Channel channel) =>
      getChannel(channel) / maxChannelValue;

  void set(Color c) {
    if (numChannels > 0) {
      r = c.r;
      g = c.g;
      b = c.b;
      a = c.a;
    }
  }

  void setColor(num r, [num g = 0, num b = 0, num a = 0]) {
    if (numChannels > 0) {
      final rd = r.toDouble();
      data[_index] = Float16.doubleToFloat16(rd);
      if (numChannels > 1) {
        final gd = g.toDouble();
        data[_index + 1] = Float16.doubleToFloat16(gd);
        if (numChannels > 2) {
          final bd = b.toDouble();
          data[_index + 2] = Float16.doubleToFloat16(bd);
          if (numChannels > 3) {
            final ad = a.toDouble();
            data[_index + 3] = Float16.doubleToFloat16(ad);
          }
        }
      }
    }
  }

  ChannelIterator get iterator => ChannelIterator(this);

  bool operator==(Object? other) {
    if (other is PixelFloat16) {
      return hashCode == other.hashCode;
    }
    if (other is List<int>) {
      if (other.length != numChannels) {
        return false;
      }
      if (data[_index] != other[0]) {
        return false;
      }
      if (numChannels > 1) {
        if (data[_index + 1] != other[1]) {
          return false;
        }
        if (numChannels > 2) {
          if (data[_index + 2] != other[2]) {
            return false;
          }
          if (numChannels > 3) {
            if (data[_index + 3] != other[3]) {
              return false;
            }
          }
        }
      }
      return true;
    }
    return false;
  }

  int get hashCode => Object.hashAll(toList());

  Color convert({ Format? format, int? numChannels, num? alpha }) =>
      convertColor(this, format: format, numChannels: numChannels,
          alpha: alpha);
}
