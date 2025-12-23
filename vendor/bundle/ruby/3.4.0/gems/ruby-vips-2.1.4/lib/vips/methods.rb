module Vips
  class Image

# @!method self.system(cmd_format, **opts)
#   Run an external command.
#   @param cmd_format [String] Command to run
#   @param opts [Hash] Set of options
#   @option opts [Array<Image>] :im Array of input images
#   @option opts [String] :out_format Format for output filename
#   @option opts [String] :in_format Format for input filename
#   @option opts [Vips::Image] :out Output Output image
#   @option opts [String] :log Output Command log
#   @return [nil, Hash<Symbol => Object>] Hash of optional output items

# @!method add(right, **opts)
#   Add two images.
#   @param right [Vips::Image] Right-hand image argument
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method subtract(right, **opts)
#   Subtract two images.
#   @param right [Vips::Image] Right-hand image argument
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method multiply(right, **opts)
#   Multiply two images.
#   @param right [Vips::Image] Right-hand image argument
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method divide(right, **opts)
#   Divide two images.
#   @param right [Vips::Image] Right-hand image argument
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method relational(right, relational, **opts)
#   Relational operation on two images.
#   @param right [Vips::Image] Right-hand image argument
#   @param relational [Vips::OperationRelational] relational to perform
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method remainder(right, **opts)
#   Remainder after integer division of two images.
#   @param right [Vips::Image] Right-hand image argument
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method boolean(right, boolean, **opts)
#   Boolean operation on two images.
#   @param right [Vips::Image] Right-hand image argument
#   @param boolean [Vips::OperationBoolean] boolean to perform
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method math2(right, math2, **opts)
#   Binary math operations.
#   @param right [Vips::Image] Right-hand image argument
#   @param math2 [Vips::OperationMath2] math to perform
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method complex2(right, cmplx, **opts)
#   Complex binary operations on two images.
#   @param right [Vips::Image] Right-hand image argument
#   @param cmplx [Vips::OperationComplex2] binary complex operation to perform
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method complexform(right, **opts)
#   Form a complex image from two real images.
#   @param right [Vips::Image] Right-hand image argument
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method self.sum(im, **opts)
#   Sum an array of images.
#   @param im [Array<Image>] Array of input images
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method invert(**opts)
#   Invert an image.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method linear(a, b, **opts)
#   Calculate (a * in + b).
#   @param a [Array<Double>] Multiply by this
#   @param b [Array<Double>] Add this
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output should be uchar
#   @return [Vips::Image] Output image

# @!method math(math, **opts)
#   Apply a math operation to an image.
#   @param math [Vips::OperationMath] math to perform
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method abs(**opts)
#   Absolute value of an image.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method sign(**opts)
#   Unit vector of pixel.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method round(round, **opts)
#   Perform a round function on an image.
#   @param round [Vips::OperationRound] rounding operation to perform
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method relational_const(relational, c, **opts)
#   Relational operations against a constant.
#   @param relational [Vips::OperationRelational] relational to perform
#   @param c [Array<Double>] Array of constants
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method remainder_const(c, **opts)
#   Remainder after integer division of an image and a constant.
#   @param c [Array<Double>] Array of constants
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method boolean_const(boolean, c, **opts)
#   Boolean operations against a constant.
#   @param boolean [Vips::OperationBoolean] boolean to perform
#   @param c [Array<Double>] Array of constants
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method math2_const(math2, c, **opts)
#   Binary math operations with a constant.
#   @param math2 [Vips::OperationMath2] math to perform
#   @param c [Array<Double>] Array of constants
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method complex(cmplx, **opts)
#   Perform a complex operation on an image.
#   @param cmplx [Vips::OperationComplex] complex to perform
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method complexget(get, **opts)
#   Get a component from a complex image.
#   @param get [Vips::OperationComplexget] complex to perform
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method avg(**opts)
#   Find image average.
#   @param opts [Hash] Set of options
#   @return [Float] Output value

# @!method min(**opts)
#   Find image minimum.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :size Number of minimum values to find
#   @option opts [Integer] :x Output Horizontal position of minimum
#   @option opts [Integer] :y Output Vertical position of minimum
#   @option opts [Array<Double>] :out_array Output Array of output values
#   @option opts [Array<Integer>] :x_array Output Array of horizontal positions
#   @option opts [Array<Integer>] :y_array Output Array of vertical positions
#   @return [Float, Hash<Symbol => Object>] Output value, Hash of optional output items

# @!method max(**opts)
#   Find image maximum.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :size Number of maximum values to find
#   @option opts [Integer] :x Output Horizontal position of maximum
#   @option opts [Integer] :y Output Vertical position of maximum
#   @option opts [Array<Double>] :out_array Output Array of output values
#   @option opts [Array<Integer>] :x_array Output Array of horizontal positions
#   @option opts [Array<Integer>] :y_array Output Array of vertical positions
#   @return [Float, Hash<Symbol => Object>] Output value, Hash of optional output items

# @!method deviate(**opts)
#   Find image standard deviation.
#   @param opts [Hash] Set of options
#   @return [Float] Output value

# @!method stats(**opts)
#   Find many image stats.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output array of statistics

# @!method hist_find(**opts)
#   Find image histogram.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :band Find histogram of band
#   @return [Vips::Image] Output histogram

# @!method hist_find_ndim(**opts)
#   Find n-dimensional image histogram.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :bins Number of bins in each dimension
#   @return [Vips::Image] Output histogram

# @!method hist_find_indexed(index, **opts)
#   Find indexed image histogram.
#   @param index [Vips::Image] Index image
#   @param opts [Hash] Set of options
#   @option opts [Vips::Combine] :combine Combine bins like this
#   @return [Vips::Image] Output histogram

# @!method hough_line(**opts)
#   Find hough line transform.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :width horizontal size of parameter space
#   @option opts [Integer] :height Vertical size of parameter space
#   @return [Vips::Image] Output image

# @!method hough_circle(**opts)
#   Find hough circle transform.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :scale Scale down dimensions by this factor
#   @option opts [Integer] :min_radius Smallest radius to search for
#   @option opts [Integer] :max_radius Largest radius to search for
#   @return [Vips::Image] Output image

# @!method project(**opts)
#   Find image projections.
#   @param opts [Hash] Set of options
#   @return [Array<Vips::Image, Vips::Image>] Sums of columns, Sums of rows

# @!method profile(**opts)
#   Find image profiles.
#   @param opts [Hash] Set of options
#   @return [Array<Vips::Image, Vips::Image>] First non-zero pixel in column, First non-zero pixel in row

# @!method measure(h, v, **opts)
#   Measure a set of patches on a color chart.
#   @param h [Integer] Number of patches across chart
#   @param v [Integer] Number of patches down chart
#   @param opts [Hash] Set of options
#   @option opts [Integer] :left Left edge of extract area
#   @option opts [Integer] :top Top edge of extract area
#   @option opts [Integer] :width Width of extract area
#   @option opts [Integer] :height Height of extract area
#   @return [Vips::Image] Output array of statistics

# @!method getpoint(x, y, **opts)
#   Read a point from an image.
#   @param x [Integer] Point to read
#   @param y [Integer] Point to read
#   @param opts [Hash] Set of options
#   @return [Array<Double>] Array of output values

# @!method find_trim(**opts)
#   Search an image for non-edge areas.
#   @param opts [Hash] Set of options
#   @option opts [Float] :threshold Object threshold
#   @option opts [Array<Double>] :background Color for background pixels
#   @return [Array<Integer, Integer, Integer, Integer>] Left edge of image, Top edge of extract area, Width of extract area, Height of extract area

# @!method copy(**opts)
#   Copy an image.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :width Image width in pixels
#   @option opts [Integer] :height Image height in pixels
#   @option opts [Integer] :bands Number of bands in image
#   @option opts [Vips::BandFormat] :format Pixel format in image
#   @option opts [Vips::Coding] :coding Pixel coding
#   @option opts [Vips::Interpretation] :interpretation Pixel interpretation
#   @option opts [Float] :xres Horizontal resolution in pixels/mm
#   @option opts [Float] :yres Vertical resolution in pixels/mm
#   @option opts [Integer] :xoffset Horizontal offset of origin
#   @option opts [Integer] :yoffset Vertical offset of origin
#   @return [Vips::Image] Output image

# @!method tilecache(**opts)
#   Cache an image as a set of tiles.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :tile_width Tile width in pixels
#   @option opts [Integer] :tile_height Tile height in pixels
#   @option opts [Integer] :max_tiles Maximum number of tiles to cache
#   @option opts [Vips::Access] :access Expected access pattern
#   @option opts [Boolean] :threaded Allow threaded access
#   @option opts [Boolean] :persistent Keep cache between evaluations
#   @return [Vips::Image] Output image

# @!method linecache(**opts)
#   Cache an image as a set of lines.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :tile_height Tile height in pixels
#   @option opts [Vips::Access] :access Expected access pattern
#   @option opts [Boolean] :threaded Allow threaded access
#   @option opts [Boolean] :persistent Keep cache between evaluations
#   @return [Vips::Image] Output image

# @!method sequential(**opts)
#   Check sequential access.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :tile_height Tile height in pixels
#   @return [Vips::Image] Output image

# @!method cache(**opts)
#   Cache an image.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :max_tiles Maximum number of tiles to cache
#   @option opts [Integer] :tile_height Tile height in pixels
#   @option opts [Integer] :tile_width Tile width in pixels
#   @return [Vips::Image] Output image

# @!method embed(x, y, width, height, **opts)
#   Embed an image in a larger image.
#   @param x [Integer] Left edge of input in output
#   @param y [Integer] Top edge of input in output
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Vips::Extend] :extend How to generate the extra pixels
#   @option opts [Array<Double>] :background Color for background pixels
#   @return [Vips::Image] Output image

# @!method gravity(direction, width, height, **opts)
#   Place an image within a larger image with a certain gravity.
#   @param direction [Vips::CompassDirection] direction to place image within width/height
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Vips::Extend] :extend How to generate the extra pixels
#   @option opts [Array<Double>] :background Color for background pixels
#   @return [Vips::Image] Output image

# @!method flip(direction, **opts)
#   Flip an image.
#   @param direction [Vips::Direction] Direction to flip image
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method insert(sub, x, y, **opts)
#   Insert image @sub into @main at @x, @y.
#   @param sub [Vips::Image] Sub-image to insert into main image
#   @param x [Integer] Left edge of sub in main
#   @param y [Integer] Top edge of sub in main
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :expand Expand output to hold all of both inputs
#   @option opts [Array<Double>] :background Color for new pixels
#   @return [Vips::Image] Output image

# @!method join(in2, direction, **opts)
#   Join a pair of images.
#   @param in2 [Vips::Image] Second input image
#   @param direction [Vips::Direction] Join left-right or up-down
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :expand Expand output to hold all of both inputs
#   @option opts [Integer] :shim Pixels between images
#   @option opts [Array<Double>] :background Colour for new pixels
#   @option opts [Vips::Align] :align Align on the low, centre or high coordinate edge
#   @return [Vips::Image] Output image

# @!method self.arrayjoin(im, **opts)
#   Join an array of images.
#   @param im [Array<Image>] Array of input images
#   @param opts [Hash] Set of options
#   @option opts [Integer] :across Number of images across grid
#   @option opts [Integer] :shim Pixels between images
#   @option opts [Array<Double>] :background Colour for new pixels
#   @option opts [Vips::Align] :halign Align on the left, centre or right
#   @option opts [Vips::Align] :valign Align on the top, centre or bottom
#   @option opts [Integer] :hspacing Horizontal spacing between images
#   @option opts [Integer] :vspacing Vertical spacing between images
#   @return [Vips::Image] Output image

# @!method extract_area(left, top, width, height, **opts)
#   Extract an area from an image.
#   @param left [Integer] Left edge of extract area
#   @param top [Integer] Top edge of extract area
#   @param width [Integer] Width of extract area
#   @param height [Integer] Height of extract area
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method crop(left, top, width, height, **opts)
#   Extract an area from an image.
#   @param left [Integer] Left edge of extract area
#   @param top [Integer] Top edge of extract area
#   @param width [Integer] Width of extract area
#   @param height [Integer] Height of extract area
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method smartcrop(width, height, **opts)
#   Extract an area from an image.
#   @param width [Integer] Width of extract area
#   @param height [Integer] Height of extract area
#   @param opts [Hash] Set of options
#   @option opts [Vips::Interesting] :interesting How to measure interestingness
#   @return [Vips::Image] Output image

# @!method extract_band(band, **opts)
#   Extract band from an image.
#   @param band [Integer] Band to extract
#   @param opts [Hash] Set of options
#   @option opts [Integer] :n Number of bands to extract
#   @return [Vips::Image] Output image

# @!method bandjoin_const(c, **opts)
#   Append a constant band to an image.
#   @param c [Array<Double>] Array of constants to add
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method self.bandrank(im, **opts)
#   Band-wise rank of a set of images.
#   @param im [Array<Image>] Array of input images
#   @param opts [Hash] Set of options
#   @option opts [Integer] :index Select this band element from sorted list
#   @return [Vips::Image] Output image

# @!method bandmean(**opts)
#   Band-wise average.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method bandbool(boolean, **opts)
#   Boolean operation across image bands.
#   @param boolean [Vips::OperationBoolean] boolean to perform
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method replicate(across, down, **opts)
#   Replicate an image.
#   @param across [Integer] Repeat this many times horizontally
#   @param down [Integer] Repeat this many times vertically
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method cast(format, **opts)
#   Cast an image.
#   @param format [Vips::BandFormat] Format to cast to
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :shift Shift integer values up and down
#   @return [Vips::Image] Output image

# @!method rot(angle, **opts)
#   Rotate an image.
#   @param angle [Vips::Angle] Angle to rotate image
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method rot45(**opts)
#   Rotate an image.
#   @param opts [Hash] Set of options
#   @option opts [Vips::Angle45] :angle Angle to rotate image
#   @return [Vips::Image] Output image

# @!method autorot(**opts)
#   Autorotate image by exif tag.
#   @param opts [Hash] Set of options
#   @option opts [Vips::Angle] :angle Output Angle image was rotated by
#   @option opts [Boolean] :flip Output Whether the image was flipped or not
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method recomb(m, **opts)
#   Linear recombination with matrix.
#   @param m [Vips::Image] matrix of coefficients
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method bandfold(**opts)
#   Fold up x axis into bands.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :factor Fold by this factor
#   @return [Vips::Image] Output image

# @!method bandunfold(**opts)
#   Unfold image bands into x axis.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :factor Unfold by this factor
#   @return [Vips::Image] Output image

# @!method flatten(**opts)
#   Flatten alpha out of an image.
#   @param opts [Hash] Set of options
#   @option opts [Array<Double>] :background Background value
#   @option opts [Float] :max_alpha Maximum value of alpha channel
#   @return [Vips::Image] Output image

# @!method premultiply(**opts)
#   Premultiply image alpha.
#   @param opts [Hash] Set of options
#   @option opts [Float] :max_alpha Maximum value of alpha channel
#   @return [Vips::Image] Output image

# @!method unpremultiply(**opts)
#   Unpremultiply image alpha.
#   @param opts [Hash] Set of options
#   @option opts [Float] :max_alpha Maximum value of alpha channel
#   @option opts [Integer] :alpha_band Unpremultiply with this alpha
#   @return [Vips::Image] Output image

# @!method grid(tile_height, across, down, **opts)
#   Grid an image.
#   @param tile_height [Integer] chop into tiles this high
#   @param across [Integer] number of tiles across
#   @param down [Integer] number of tiles down
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method transpose3d(**opts)
#   Transpose3d an image.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page_height Height of each input page
#   @return [Vips::Image] Output image

# @!method wrap(**opts)
#   Wrap image origin.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :x Left edge of input in output
#   @option opts [Integer] :y Top edge of input in output
#   @return [Vips::Image] Output image

# @!method zoom(xfac, yfac, **opts)
#   Zoom an image.
#   @param xfac [Integer] Horizontal zoom factor
#   @param yfac [Integer] Vertical zoom factor
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method subsample(xfac, yfac, **opts)
#   Subsample an image.
#   @param xfac [Integer] Horizontal subsample factor
#   @param yfac [Integer] Vertical subsample factor
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :point Point sample
#   @return [Vips::Image] Output image

# @!method msb(**opts)
#   Pick most-significant byte from an image.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :band Band to msb
#   @return [Vips::Image] Output image

# @!method byteswap(**opts)
#   Byteswap an image.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method falsecolour(**opts)
#   False-color an image.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method gamma(**opts)
#   Gamma an image.
#   @param opts [Hash] Set of options
#   @option opts [Float] :exponent Gamma factor
#   @return [Vips::Image] Output image

# @!method composite2(overlay, mode, **opts)
#   Blend a pair of images with a blend mode.
#   @param overlay [Vips::Image] Overlay image
#   @param mode [Vips::BlendMode] VipsBlendMode to join with
#   @param opts [Hash] Set of options
#   @option opts [Integer] :x x position of overlay
#   @option opts [Integer] :y y position of overlay
#   @option opts [Vips::Interpretation] :compositing_space Composite images in this colour space
#   @option opts [Boolean] :premultiplied Images have premultiplied alpha
#   @return [Vips::Image] Output image

# @!method self.black(width, height, **opts)
#   Make a black image.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Integer] :bands Number of bands in image
#   @return [Vips::Image] Output image

# @!method self.gaussnoise(width, height, **opts)
#   Make a gaussnoise image.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Float] :sigma Standard deviation of pixels in generated image
#   @option opts [Float] :mean Mean of pixels in generated image
#   @option opts [Integer] :seed Random number seed
#   @return [Vips::Image] Output image

# @!method self.xyz(width, height, **opts)
#   Make an image where pixel values are coordinates.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Integer] :csize Size of third dimension
#   @option opts [Integer] :dsize Size of fourth dimension
#   @option opts [Integer] :esize Size of fifth dimension
#   @return [Vips::Image] Output image

# @!method self.gaussmat(sigma, min_ampl, **opts)
#   Make a gaussian image.
#   @param sigma [Float] Sigma of Gaussian
#   @param min_ampl [Float] Minimum amplitude of Gaussian
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :separable Generate separable Gaussian
#   @option opts [Vips::Precision] :precision Generate with this precision
#   @return [Vips::Image] Output image

# @!method self.logmat(sigma, min_ampl, **opts)
#   Make a laplacian of gaussian image.
#   @param sigma [Float] Radius of Logmatian
#   @param min_ampl [Float] Minimum amplitude of Logmatian
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :separable Generate separable Logmatian
#   @option opts [Vips::Precision] :precision Generate with this precision
#   @return [Vips::Image] Output image

# @!method self.text(text, **opts)
#   Make a text image.
#   @param text [String] Text to render
#   @param opts [Hash] Set of options
#   @option opts [String] :font Font to render with
#   @option opts [Integer] :width Maximum image width in pixels
#   @option opts [Integer] :height Maximum image height in pixels
#   @option opts [Vips::Align] :align Align on the low, centre or high edge
#   @option opts [Boolean] :rgba Enable RGBA output
#   @option opts [Integer] :dpi DPI to render at
#   @option opts [Boolean] :justify Justify lines
#   @option opts [Integer] :spacing Line spacing
#   @option opts [String] :fontfile Load this font file
#   @option opts [Integer] :autofit_dpi Output DPI selected by autofit
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.eye(width, height, **opts)
#   Make an image showing the eye's spatial response.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Float] :factor Maximum spatial frequency
#   @return [Vips::Image] Output image

# @!method self.grey(width, height, **opts)
#   Make a grey ramp image.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @return [Vips::Image] Output image

# @!method self.zone(width, height, **opts)
#   Make a zone plate.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @return [Vips::Image] Output image

# @!method self.sines(width, height, **opts)
#   Make a 2d sine wave.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Float] :hfreq Horizontal spatial frequency
#   @option opts [Float] :vfreq Vertical spatial frequency
#   @return [Vips::Image] Output image

# @!method self.mask_ideal(width, height, frequency_cutoff, **opts)
#   Make an ideal filter.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param frequency_cutoff [Float] Frequency cutoff
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Boolean] :nodc Remove DC component
#   @option opts [Boolean] :reject Invert the sense of the filter
#   @option opts [Boolean] :optical Rotate quadrants to optical space
#   @return [Vips::Image] Output image

# @!method self.mask_ideal_ring(width, height, frequency_cutoff, ringwidth, **opts)
#   Make an ideal ring filter.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param frequency_cutoff [Float] Frequency cutoff
#   @param ringwidth [Float] Ringwidth
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Boolean] :nodc Remove DC component
#   @option opts [Boolean] :reject Invert the sense of the filter
#   @option opts [Boolean] :optical Rotate quadrants to optical space
#   @return [Vips::Image] Output image

# @!method self.mask_ideal_band(width, height, frequency_cutoff_x, frequency_cutoff_y, radius, **opts)
#   Make an ideal band filter.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param frequency_cutoff_x [Float] Frequency cutoff x
#   @param frequency_cutoff_y [Float] Frequency cutoff y
#   @param radius [Float] radius of circle
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Boolean] :nodc Remove DC component
#   @option opts [Boolean] :reject Invert the sense of the filter
#   @option opts [Boolean] :optical Rotate quadrants to optical space
#   @return [Vips::Image] Output image

# @!method self.mask_butterworth(width, height, order, frequency_cutoff, amplitude_cutoff, **opts)
#   Make a butterworth filter.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param order [Float] Filter order
#   @param frequency_cutoff [Float] Frequency cutoff
#   @param amplitude_cutoff [Float] Amplitude cutoff
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Boolean] :nodc Remove DC component
#   @option opts [Boolean] :reject Invert the sense of the filter
#   @option opts [Boolean] :optical Rotate quadrants to optical space
#   @return [Vips::Image] Output image

# @!method self.mask_butterworth_ring(width, height, order, frequency_cutoff, amplitude_cutoff, ringwidth, **opts)
#   Make a butterworth ring filter.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param order [Float] Filter order
#   @param frequency_cutoff [Float] Frequency cutoff
#   @param amplitude_cutoff [Float] Amplitude cutoff
#   @param ringwidth [Float] Ringwidth
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Boolean] :nodc Remove DC component
#   @option opts [Boolean] :reject Invert the sense of the filter
#   @option opts [Boolean] :optical Rotate quadrants to optical space
#   @return [Vips::Image] Output image

# @!method self.mask_butterworth_band(width, height, order, frequency_cutoff_x, frequency_cutoff_y, radius, amplitude_cutoff, **opts)
#   Make a butterworth_band filter.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param order [Float] Filter order
#   @param frequency_cutoff_x [Float] Frequency cutoff x
#   @param frequency_cutoff_y [Float] Frequency cutoff y
#   @param radius [Float] radius of circle
#   @param amplitude_cutoff [Float] Amplitude cutoff
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Boolean] :nodc Remove DC component
#   @option opts [Boolean] :reject Invert the sense of the filter
#   @option opts [Boolean] :optical Rotate quadrants to optical space
#   @return [Vips::Image] Output image

# @!method self.mask_gaussian(width, height, frequency_cutoff, amplitude_cutoff, **opts)
#   Make a gaussian filter.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param frequency_cutoff [Float] Frequency cutoff
#   @param amplitude_cutoff [Float] Amplitude cutoff
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Boolean] :nodc Remove DC component
#   @option opts [Boolean] :reject Invert the sense of the filter
#   @option opts [Boolean] :optical Rotate quadrants to optical space
#   @return [Vips::Image] Output image

# @!method self.mask_gaussian_ring(width, height, frequency_cutoff, amplitude_cutoff, ringwidth, **opts)
#   Make a gaussian ring filter.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param frequency_cutoff [Float] Frequency cutoff
#   @param amplitude_cutoff [Float] Amplitude cutoff
#   @param ringwidth [Float] Ringwidth
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Boolean] :nodc Remove DC component
#   @option opts [Boolean] :reject Invert the sense of the filter
#   @option opts [Boolean] :optical Rotate quadrants to optical space
#   @return [Vips::Image] Output image

# @!method self.mask_gaussian_band(width, height, frequency_cutoff_x, frequency_cutoff_y, radius, amplitude_cutoff, **opts)
#   Make a gaussian filter.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param frequency_cutoff_x [Float] Frequency cutoff x
#   @param frequency_cutoff_y [Float] Frequency cutoff y
#   @param radius [Float] radius of circle
#   @param amplitude_cutoff [Float] Amplitude cutoff
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Boolean] :nodc Remove DC component
#   @option opts [Boolean] :reject Invert the sense of the filter
#   @option opts [Boolean] :optical Rotate quadrants to optical space
#   @return [Vips::Image] Output image

# @!method self.mask_fractal(width, height, fractal_dimension, **opts)
#   Make fractal filter.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param fractal_dimension [Float] Fractal dimension
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Boolean] :nodc Remove DC component
#   @option opts [Boolean] :reject Invert the sense of the filter
#   @option opts [Boolean] :optical Rotate quadrants to optical space
#   @return [Vips::Image] Output image

# @!method buildlut(**opts)
#   Build a look-up table.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method invertlut(**opts)
#   Build an inverted look-up table.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :size LUT size to generate
#   @return [Vips::Image] Output image

# @!method self.tonelut(**opts)
#   Build a look-up table.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :in_max Size of LUT to build
#   @option opts [Integer] :out_max Maximum value in output LUT
#   @option opts [Float] :Lb Lowest value in output
#   @option opts [Float] :Lw Highest value in output
#   @option opts [Float] :Ps Position of shadow
#   @option opts [Float] :Pm Position of mid-tones
#   @option opts [Float] :Ph Position of highlights
#   @option opts [Float] :S Adjust shadows by this much
#   @option opts [Float] :M Adjust mid-tones by this much
#   @option opts [Float] :H Adjust highlights by this much
#   @return [Vips::Image] Output image

# @!method self.identity(**opts)
#   Make a 1d image where pixel values are indexes.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :bands Number of bands in LUT
#   @option opts [Boolean] :ushort Create a 16-bit LUT
#   @option opts [Integer] :size Size of 16-bit LUT
#   @return [Vips::Image] Output image

# @!method self.fractsurf(width, height, fractal_dimension, **opts)
#   Make a fractal surface.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param fractal_dimension [Float] Fractal dimension
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method self.worley(width, height, **opts)
#   Make a worley noise image.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Integer] :cell_size Size of Worley cells
#   @option opts [Integer] :seed Random number seed
#   @return [Vips::Image] Output image

# @!method self.perlin(width, height, **opts)
#   Make a perlin noise image.
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Integer] :cell_size Size of Perlin cells
#   @option opts [Boolean] :uchar Output an unsigned char image
#   @option opts [Integer] :seed Random number seed
#   @return [Vips::Image] Output image

# @!method self.switch(tests, **opts)
#   Find the index of the first non-zero pixel in tests.
#   @param tests [Array<Image>] Table of images to test
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method self.csvload(filename, **opts)
#   Load csv.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :skip Skip this many lines at the start of the file
#   @option opts [Integer] :lines Read this many lines from the file
#   @option opts [String] :whitespace Set of whitespace characters
#   @option opts [String] :separator Set of separator characters
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.csvload_source(source, **opts)
#   Load csv.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :skip Skip this many lines at the start of the file
#   @option opts [Integer] :lines Read this many lines from the file
#   @option opts [String] :whitespace Set of whitespace characters
#   @option opts [String] :separator Set of separator characters
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.matrixload(filename, **opts)
#   Load matrix.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.matrixload_source(source, **opts)
#   Load matrix.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.rawload(filename, width, height, bands, **opts)
#   Load raw data from a file.
#   @param filename [String] Filename to load from
#   @param width [Integer] Image width in pixels
#   @param height [Integer] Image height in pixels
#   @param bands [Integer] Number of bands in image
#   @param opts [Hash] Set of options
#   @option opts [guint64] :offset Offset in bytes from start of file
#   @option opts [Vips::BandFormat] :format Pixel format in image
#   @option opts [Vips::Interpretation] :interpretation Pixel interpretation
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.vipsload(filename, **opts)
#   Load vips from file.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.vipsload_source(source, **opts)
#   Load vips from source.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.analyzeload(filename, **opts)
#   Load an analyze6 image.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.ppmload(filename, **opts)
#   Load ppm from file.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.ppmload_source(source, **opts)
#   Load ppm base class.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.radload(filename, **opts)
#   Load a radiance image from a file.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.radload_buffer(buffer, **opts)
#   Load rad from buffer.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.radload_source(source, **opts)
#   Load rad from source.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.pdfload(filename, **opts)
#   Load pdf from file.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Integer] :n Load this many pages
#   @option opts [Float] :dpi Render at this DPI
#   @option opts [Float] :scale Scale output by this factor
#   @option opts [Array<Double>] :background Background value
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.pdfload_buffer(buffer, **opts)
#   Load pdf from buffer.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Integer] :n Load this many pages
#   @option opts [Float] :dpi Render at this DPI
#   @option opts [Float] :scale Scale output by this factor
#   @option opts [Array<Double>] :background Background value
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.pdfload_source(source, **opts)
#   Load pdf from source.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Integer] :n Load this many pages
#   @option opts [Float] :dpi Render at this DPI
#   @option opts [Float] :scale Scale output by this factor
#   @option opts [Array<Double>] :background Background value
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.svgload(filename, **opts)
#   Load svg with rsvg.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Float] :dpi Render at this DPI
#   @option opts [Float] :scale Scale output by this factor
#   @option opts [Boolean] :unlimited Allow SVG of any size
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.svgload_buffer(buffer, **opts)
#   Load svg with rsvg.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [Float] :dpi Render at this DPI
#   @option opts [Float] :scale Scale output by this factor
#   @option opts [Boolean] :unlimited Allow SVG of any size
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.svgload_source(source, **opts)
#   Load svg from source.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Float] :dpi Render at this DPI
#   @option opts [Float] :scale Scale output by this factor
#   @option opts [Boolean] :unlimited Allow SVG of any size
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.jxlload(filename, **opts)
#   Load jpeg-xl image.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.jxlload_buffer(buffer, **opts)
#   Load jpeg-xl image.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.jxlload_source(source, **opts)
#   Load jpeg-xl image.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.jp2kload(filename, **opts)
#   Load jpeg2000 image.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the image
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.jp2kload_buffer(buffer, **opts)
#   Load jpeg2000 image.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the image
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.jp2kload_source(source, **opts)
#   Load jpeg2000 image.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the image
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.gifload(filename, **opts)
#   Load gif with libnsgif.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :n Load this many pages
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.gifload_buffer(buffer, **opts)
#   Load gif with libnsgif.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :n Load this many pages
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.gifload_source(source, **opts)
#   Load gif from source.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :n Load this many pages
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.pngload(filename, **opts)
#   Load png from file.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :unlimited Remove all denial of service limits
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.pngload_buffer(buffer, **opts)
#   Load png from buffer.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :unlimited Remove all denial of service limits
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.pngload_source(source, **opts)
#   Load png from source.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :unlimited Remove all denial of service limits
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.matload(filename, **opts)
#   Load mat from file.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.jpegload(filename, **opts)
#   Load jpeg from file.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :shrink Shrink factor on load
#   @option opts [Boolean] :autorotate Rotate image using exif orientation
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.jpegload_buffer(buffer, **opts)
#   Load jpeg from buffer.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :shrink Shrink factor on load
#   @option opts [Boolean] :autorotate Rotate image using exif orientation
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.jpegload_source(source, **opts)
#   Load image from jpeg source.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :shrink Shrink factor on load
#   @option opts [Boolean] :autorotate Rotate image using exif orientation
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.webpload(filename, **opts)
#   Load webp from file.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Integer] :n Load this many pages
#   @option opts [Float] :scale Scale factor on load
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.webpload_buffer(buffer, **opts)
#   Load webp from buffer.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Integer] :n Load this many pages
#   @option opts [Float] :scale Scale factor on load
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.webpload_source(source, **opts)
#   Load webp from source.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Integer] :n Load this many pages
#   @option opts [Float] :scale Scale factor on load
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.tiffload(filename, **opts)
#   Load tiff from file.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the image
#   @option opts [Integer] :subifd Select subifd index
#   @option opts [Integer] :n Load this many pages
#   @option opts [Boolean] :autorotate Rotate image using orientation tag
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.tiffload_buffer(buffer, **opts)
#   Load tiff from buffer.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the image
#   @option opts [Integer] :subifd Select subifd index
#   @option opts [Integer] :n Load this many pages
#   @option opts [Boolean] :autorotate Rotate image using orientation tag
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.tiffload_source(source, **opts)
#   Load tiff from source.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the image
#   @option opts [Integer] :subifd Select subifd index
#   @option opts [Integer] :n Load this many pages
#   @option opts [Boolean] :autorotate Rotate image using orientation tag
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.openslideload(filename, **opts)
#   Load file with openslide.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :attach_associated Attach all associated images
#   @option opts [Integer] :level Load this level from the file
#   @option opts [Boolean] :autocrop Crop to image bounds
#   @option opts [String] :associated Load this associated image
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.openslideload_source(source, **opts)
#   Load source with openslide.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :attach_associated Attach all associated images
#   @option opts [Integer] :level Load this level from the file
#   @option opts [Boolean] :autocrop Crop to image bounds
#   @option opts [String] :associated Load this associated image
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.magickload(filename, **opts)
#   Load file with imagemagick.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [String] :density Canvas resolution for rendering vector formats like SVG
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Integer] :n Load this many pages
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.magickload_buffer(buffer, **opts)
#   Load buffer with imagemagick.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [String] :density Canvas resolution for rendering vector formats like SVG
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Integer] :n Load this many pages
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.fitsload(filename, **opts)
#   Load a fits image.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.fitsload_source(source, **opts)
#   Load fits from a source.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.openexrload(filename, **opts)
#   Load an openexr image.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.niftiload(filename, **opts)
#   Load nifti volume.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.niftiload_source(source, **opts)
#   Load nifti volumes.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.heifload(filename, **opts)
#   Load a heif image.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Integer] :n Load this many pages
#   @option opts [Boolean] :thumbnail Fetch thumbnail image
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.heifload_buffer(buffer, **opts)
#   Load a heif image.
#   @param buffer [VipsBlob] Buffer to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Integer] :n Load this many pages
#   @option opts [Boolean] :thumbnail Fetch thumbnail image
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method self.heifload_source(source, **opts)
#   Load a heif image.
#   @param source [Vips::Source] Source to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :page Load this page from the file
#   @option opts [Integer] :n Load this many pages
#   @option opts [Boolean] :thumbnail Fetch thumbnail image
#   @option opts [Boolean] :memory Force open via memory
#   @option opts [Vips::Access] :access Required access pattern for this file
#   @option opts [Vips::FailOn] :fail_on Error level to fail on
#   @option opts [Vips::ForeignFlags] :flags Output Flags for this file
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method csvsave(filename, **opts)
#   Save image to csv.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [String] :separator Separator characters
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method csvsave_target(target, **opts)
#   Save image to csv.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [String] :separator Separator characters
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method matrixsave(filename, **opts)
#   Save image to matrix.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method matrixsave_target(target, **opts)
#   Save image to matrix.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method matrixprint(**opts)
#   Print matrix.
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method rawsave(filename, **opts)
#   Save image to raw file.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method rawsave_fd(fd, **opts)
#   Write raw image to file descriptor.
#   @param fd [Integer] File descriptor to write to
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method vipssave(filename, **opts)
#   Save image to file in vips format.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method vipssave_target(target, **opts)
#   Save image to target in vips format.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method ppmsave(filename, **opts)
#   Save image to ppm file.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Vips::ForeignPpmFormat] :format Format to save in
#   @option opts [Boolean] :ascii save as ascii
#   @option opts [Integer] :bitdepth set to 1 to write as a 1 bit image
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method ppmsave_target(target, **opts)
#   Save to ppm.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [Vips::ForeignPpmFormat] :format Format to save in
#   @option opts [Boolean] :ascii save as ascii
#   @option opts [Integer] :bitdepth set to 1 to write as a 1 bit image
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method radsave(filename, **opts)
#   Save image to radiance file.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method radsave_buffer(**opts)
#   Save image to radiance buffer.
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [VipsBlob] Buffer to save to

# @!method radsave_target(target, **opts)
#   Save image to radiance target.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method jxlsave(filename, **opts)
#   Save image in jpeg-xl format.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :tier Decode speed tier
#   @option opts [Float] :distance Target butteraugli distance
#   @option opts [Integer] :effort Encoding effort
#   @option opts [Boolean] :lossless Enable lossless compression
#   @option opts [Integer] :Q Quality factor
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method jxlsave_buffer(**opts)
#   Save image in jpeg-xl format.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :tier Decode speed tier
#   @option opts [Float] :distance Target butteraugli distance
#   @option opts [Integer] :effort Encoding effort
#   @option opts [Boolean] :lossless Enable lossless compression
#   @option opts [Integer] :Q Quality factor
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [VipsBlob] Buffer to save to

# @!method jxlsave_target(target, **opts)
#   Save image in jpeg-xl format.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [Integer] :tier Decode speed tier
#   @option opts [Float] :distance Target butteraugli distance
#   @option opts [Integer] :effort Encoding effort
#   @option opts [Boolean] :lossless Enable lossless compression
#   @option opts [Integer] :Q Quality factor
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method jp2ksave(filename, **opts)
#   Save image in jpeg2000 format.
#   @param filename [String] Filename to load from
#   @param opts [Hash] Set of options
#   @option opts [Integer] :tile_width Tile width in pixels
#   @option opts [Integer] :tile_height Tile height in pixels
#   @option opts [Boolean] :lossless Enable lossless compression
#   @option opts [Integer] :Q Q factor
#   @option opts [Vips::ForeignSubsample] :subsample_mode Select chroma subsample operation mode
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method jp2ksave_buffer(**opts)
#   Save image in jpeg2000 format.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :tile_width Tile width in pixels
#   @option opts [Integer] :tile_height Tile height in pixels
#   @option opts [Boolean] :lossless Enable lossless compression
#   @option opts [Integer] :Q Q factor
#   @option opts [Vips::ForeignSubsample] :subsample_mode Select chroma subsample operation mode
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [VipsBlob] Buffer to save to

# @!method jp2ksave_target(target, **opts)
#   Save image in jpeg2000 format.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [Integer] :tile_width Tile width in pixels
#   @option opts [Integer] :tile_height Tile height in pixels
#   @option opts [Boolean] :lossless Enable lossless compression
#   @option opts [Integer] :Q Q factor
#   @option opts [Vips::ForeignSubsample] :subsample_mode Select chroma subsample operation mode
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method gifsave(filename, **opts)
#   Save as gif.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Float] :dither Amount of dithering
#   @option opts [Integer] :effort Quantisation effort
#   @option opts [Integer] :bitdepth Number of bits per pixel
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method gifsave_buffer(**opts)
#   Save as gif.
#   @param opts [Hash] Set of options
#   @option opts [Float] :dither Amount of dithering
#   @option opts [Integer] :effort Quantisation effort
#   @option opts [Integer] :bitdepth Number of bits per pixel
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [VipsBlob] Buffer to save to

# @!method gifsave_target(target, **opts)
#   Save as gif.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [Float] :dither Amount of dithering
#   @option opts [Integer] :effort Quantisation effort
#   @option opts [Integer] :bitdepth Number of bits per pixel
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method dzsave(filename, **opts)
#   Save image to deepzoom file.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [String] :basename Base name to save to
#   @option opts [Vips::ForeignDzLayout] :layout Directory layout
#   @option opts [String] :suffix Filename suffix for tiles
#   @option opts [Integer] :overlap Tile overlap in pixels
#   @option opts [Integer] :tile_size Tile size in pixels
#   @option opts [Boolean] :centre Center image in tile
#   @option opts [Vips::ForeignDzDepth] :depth Pyramid depth
#   @option opts [Vips::Angle] :angle Rotate image during save
#   @option opts [Vips::ForeignDzContainer] :container Pyramid container type
#   @option opts [Boolean] :properties Write a properties file to the output directory
#   @option opts [Integer] :compression ZIP deflate compression level
#   @option opts [Vips::RegionShrink] :region_shrink Method to shrink regions
#   @option opts [Integer] :skip_blanks Skip tiles which are nearly equal to the background
#   @option opts [Boolean] :no_strip Don't strip tile metadata
#   @option opts [String] :id Resource ID
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method dzsave_buffer(**opts)
#   Save image to dz buffer.
#   @param opts [Hash] Set of options
#   @option opts [String] :basename Base name to save to
#   @option opts [Vips::ForeignDzLayout] :layout Directory layout
#   @option opts [String] :suffix Filename suffix for tiles
#   @option opts [Integer] :overlap Tile overlap in pixels
#   @option opts [Integer] :tile_size Tile size in pixels
#   @option opts [Boolean] :centre Center image in tile
#   @option opts [Vips::ForeignDzDepth] :depth Pyramid depth
#   @option opts [Vips::Angle] :angle Rotate image during save
#   @option opts [Vips::ForeignDzContainer] :container Pyramid container type
#   @option opts [Boolean] :properties Write a properties file to the output directory
#   @option opts [Integer] :compression ZIP deflate compression level
#   @option opts [Vips::RegionShrink] :region_shrink Method to shrink regions
#   @option opts [Integer] :skip_blanks Skip tiles which are nearly equal to the background
#   @option opts [Boolean] :no_strip Don't strip tile metadata
#   @option opts [String] :id Resource ID
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [VipsBlob] Buffer to save to

# @!method pngsave(filename, **opts)
#   Save image to png file.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Integer] :compression Compression factor
#   @option opts [Boolean] :interlace Interlace image
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Vips::ForeignPngFilter] :filter libpng row filter flag(s)
#   @option opts [Boolean] :palette Quantise to 8bpp palette
#   @option opts [Integer] :Q Quantisation quality
#   @option opts [Float] :dither Amount of dithering
#   @option opts [Integer] :bitdepth Write as a 1, 2, 4 or 8 bit image
#   @option opts [Integer] :effort Quantisation CPU effort
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method pngsave_buffer(**opts)
#   Save image to png buffer.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :compression Compression factor
#   @option opts [Boolean] :interlace Interlace image
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Vips::ForeignPngFilter] :filter libpng row filter flag(s)
#   @option opts [Boolean] :palette Quantise to 8bpp palette
#   @option opts [Integer] :Q Quantisation quality
#   @option opts [Float] :dither Amount of dithering
#   @option opts [Integer] :bitdepth Write as a 1, 2, 4 or 8 bit image
#   @option opts [Integer] :effort Quantisation CPU effort
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [VipsBlob] Buffer to save to

# @!method pngsave_target(target, **opts)
#   Save image to target as png.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [Integer] :compression Compression factor
#   @option opts [Boolean] :interlace Interlace image
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Vips::ForeignPngFilter] :filter libpng row filter flag(s)
#   @option opts [Boolean] :palette Quantise to 8bpp palette
#   @option opts [Integer] :Q Quantisation quality
#   @option opts [Float] :dither Amount of dithering
#   @option opts [Integer] :bitdepth Write as a 1, 2, 4 or 8 bit image
#   @option opts [Integer] :effort Quantisation CPU effort
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method jpegsave(filename, **opts)
#   Save image to jpeg file.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Integer] :Q Q factor
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Boolean] :optimize_coding Compute optimal Huffman coding tables
#   @option opts [Boolean] :interlace Generate an interlaced (progressive) jpeg
#   @option opts [Boolean] :trellis_quant Apply trellis quantisation to each 8x8 block
#   @option opts [Boolean] :overshoot_deringing Apply overshooting to samples with extreme values
#   @option opts [Boolean] :optimize_scans Split spectrum of DCT coefficients into separate scans
#   @option opts [Integer] :quant_table Use predefined quantization table with given index
#   @option opts [Vips::ForeignSubsample] :subsample_mode Select chroma subsample operation mode
#   @option opts [Integer] :restart_interval Add restart markers every specified number of mcu
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method jpegsave_buffer(**opts)
#   Save image to jpeg buffer.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :Q Q factor
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Boolean] :optimize_coding Compute optimal Huffman coding tables
#   @option opts [Boolean] :interlace Generate an interlaced (progressive) jpeg
#   @option opts [Boolean] :trellis_quant Apply trellis quantisation to each 8x8 block
#   @option opts [Boolean] :overshoot_deringing Apply overshooting to samples with extreme values
#   @option opts [Boolean] :optimize_scans Split spectrum of DCT coefficients into separate scans
#   @option opts [Integer] :quant_table Use predefined quantization table with given index
#   @option opts [Vips::ForeignSubsample] :subsample_mode Select chroma subsample operation mode
#   @option opts [Integer] :restart_interval Add restart markers every specified number of mcu
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [VipsBlob] Buffer to save to

# @!method jpegsave_target(target, **opts)
#   Save image to jpeg target.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [Integer] :Q Q factor
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Boolean] :optimize_coding Compute optimal Huffman coding tables
#   @option opts [Boolean] :interlace Generate an interlaced (progressive) jpeg
#   @option opts [Boolean] :trellis_quant Apply trellis quantisation to each 8x8 block
#   @option opts [Boolean] :overshoot_deringing Apply overshooting to samples with extreme values
#   @option opts [Boolean] :optimize_scans Split spectrum of DCT coefficients into separate scans
#   @option opts [Integer] :quant_table Use predefined quantization table with given index
#   @option opts [Vips::ForeignSubsample] :subsample_mode Select chroma subsample operation mode
#   @option opts [Integer] :restart_interval Add restart markers every specified number of mcu
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method jpegsave_mime(**opts)
#   Save image to jpeg mime.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :Q Q factor
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Boolean] :optimize_coding Compute optimal Huffman coding tables
#   @option opts [Boolean] :interlace Generate an interlaced (progressive) jpeg
#   @option opts [Boolean] :trellis_quant Apply trellis quantisation to each 8x8 block
#   @option opts [Boolean] :overshoot_deringing Apply overshooting to samples with extreme values
#   @option opts [Boolean] :optimize_scans Split spectrum of DCT coefficients into separate scans
#   @option opts [Integer] :quant_table Use predefined quantization table with given index
#   @option opts [Vips::ForeignSubsample] :subsample_mode Select chroma subsample operation mode
#   @option opts [Integer] :restart_interval Add restart markers every specified number of mcu
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method webpsave(filename, **opts)
#   Save image to webp file.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Integer] :Q Q factor
#   @option opts [Boolean] :lossless enable lossless compression
#   @option opts [Vips::ForeignWebpPreset] :preset Preset for lossy compression
#   @option opts [Boolean] :smart_subsample Enable high quality chroma subsampling
#   @option opts [Boolean] :near_lossless Enable preprocessing in lossless mode (uses Q)
#   @option opts [Integer] :alpha_q Change alpha plane fidelity for lossy compression
#   @option opts [Boolean] :min_size Optimise for minium size
#   @option opts [Integer] :kmin Minimum number of frames between key frames
#   @option opts [Integer] :kmax Maximum number of frames between key frames
#   @option opts [Integer] :effort Level of CPU effort to reduce file size
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method webpsave_buffer(**opts)
#   Save image to webp buffer.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :Q Q factor
#   @option opts [Boolean] :lossless enable lossless compression
#   @option opts [Vips::ForeignWebpPreset] :preset Preset for lossy compression
#   @option opts [Boolean] :smart_subsample Enable high quality chroma subsampling
#   @option opts [Boolean] :near_lossless Enable preprocessing in lossless mode (uses Q)
#   @option opts [Integer] :alpha_q Change alpha plane fidelity for lossy compression
#   @option opts [Boolean] :min_size Optimise for minium size
#   @option opts [Integer] :kmin Minimum number of frames between key frames
#   @option opts [Integer] :kmax Maximum number of frames between key frames
#   @option opts [Integer] :effort Level of CPU effort to reduce file size
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [VipsBlob] Buffer to save to

# @!method webpsave_target(target, **opts)
#   Save image to webp target.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [Integer] :Q Q factor
#   @option opts [Boolean] :lossless enable lossless compression
#   @option opts [Vips::ForeignWebpPreset] :preset Preset for lossy compression
#   @option opts [Boolean] :smart_subsample Enable high quality chroma subsampling
#   @option opts [Boolean] :near_lossless Enable preprocessing in lossless mode (uses Q)
#   @option opts [Integer] :alpha_q Change alpha plane fidelity for lossy compression
#   @option opts [Boolean] :min_size Optimise for minium size
#   @option opts [Integer] :kmin Minimum number of frames between key frames
#   @option opts [Integer] :kmax Maximum number of frames between key frames
#   @option opts [Integer] :effort Level of CPU effort to reduce file size
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method tiffsave(filename, **opts)
#   Save image to tiff file.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Vips::ForeignTiffCompression] :compression Compression for this file
#   @option opts [Integer] :Q Q factor
#   @option opts [Vips::ForeignTiffPredictor] :predictor Compression prediction
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Boolean] :tile Write a tiled tiff
#   @option opts [Integer] :tile_width Tile width in pixels
#   @option opts [Integer] :tile_height Tile height in pixels
#   @option opts [Boolean] :pyramid Write a pyramidal tiff
#   @option opts [Boolean] :miniswhite Use 0 for white in 1-bit images
#   @option opts [Integer] :bitdepth Write as a 1, 2, 4 or 8 bit image
#   @option opts [Vips::ForeignTiffResunit] :resunit Resolution unit
#   @option opts [Float] :xres Horizontal resolution in pixels/mm
#   @option opts [Float] :yres Vertical resolution in pixels/mm
#   @option opts [Boolean] :bigtiff Write a bigtiff image
#   @option opts [Boolean] :properties Write a properties document to IMAGEDESCRIPTION
#   @option opts [Vips::RegionShrink] :region_shrink Method to shrink regions
#   @option opts [Integer] :level ZSTD compression level
#   @option opts [Boolean] :lossless Enable WEBP lossless mode
#   @option opts [Vips::ForeignDzDepth] :depth Pyramid depth
#   @option opts [Boolean] :subifd Save pyr layers as sub-IFDs
#   @option opts [Boolean] :premultiply Save with premultiplied alpha
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method tiffsave_buffer(**opts)
#   Save image to tiff buffer.
#   @param opts [Hash] Set of options
#   @option opts [Vips::ForeignTiffCompression] :compression Compression for this file
#   @option opts [Integer] :Q Q factor
#   @option opts [Vips::ForeignTiffPredictor] :predictor Compression prediction
#   @option opts [String] :profile ICC profile to embed
#   @option opts [Boolean] :tile Write a tiled tiff
#   @option opts [Integer] :tile_width Tile width in pixels
#   @option opts [Integer] :tile_height Tile height in pixels
#   @option opts [Boolean] :pyramid Write a pyramidal tiff
#   @option opts [Boolean] :miniswhite Use 0 for white in 1-bit images
#   @option opts [Integer] :bitdepth Write as a 1, 2, 4 or 8 bit image
#   @option opts [Vips::ForeignTiffResunit] :resunit Resolution unit
#   @option opts [Float] :xres Horizontal resolution in pixels/mm
#   @option opts [Float] :yres Vertical resolution in pixels/mm
#   @option opts [Boolean] :bigtiff Write a bigtiff image
#   @option opts [Boolean] :properties Write a properties document to IMAGEDESCRIPTION
#   @option opts [Vips::RegionShrink] :region_shrink Method to shrink regions
#   @option opts [Integer] :level ZSTD compression level
#   @option opts [Boolean] :lossless Enable WEBP lossless mode
#   @option opts [Vips::ForeignDzDepth] :depth Pyramid depth
#   @option opts [Boolean] :subifd Save pyr layers as sub-IFDs
#   @option opts [Boolean] :premultiply Save with premultiplied alpha
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [VipsBlob] Buffer to save to

# @!method magicksave(filename, **opts)
#   Save file with imagemagick.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [String] :format Format to save in
#   @option opts [Integer] :quality Quality to use
#   @option opts [Boolean] :optimize_gif_frames Apply GIF frames optimization
#   @option opts [Boolean] :optimize_gif_transparency Apply GIF transparency optimization
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method magicksave_buffer(**opts)
#   Save image to magick buffer.
#   @param opts [Hash] Set of options
#   @option opts [String] :format Format to save in
#   @option opts [Integer] :quality Quality to use
#   @option opts [Boolean] :optimize_gif_frames Apply GIF frames optimization
#   @option opts [Boolean] :optimize_gif_transparency Apply GIF transparency optimization
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [VipsBlob] Buffer to save to

# @!method fitssave(filename, **opts)
#   Save image to fits file.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method niftisave(filename, **opts)
#   Save image to nifti file.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method heifsave(filename, **opts)
#   Save image in heif format.
#   @param filename [String] Filename to save to
#   @param opts [Hash] Set of options
#   @option opts [Integer] :Q Q factor
#   @option opts [Boolean] :lossless Enable lossless compression
#   @option opts [Vips::ForeignHeifCompression] :compression Compression format
#   @option opts [Integer] :effort CPU effort
#   @option opts [Vips::ForeignSubsample] :subsample_mode Select chroma subsample operation mode
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method heifsave_buffer(**opts)
#   Save image in heif format.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :Q Q factor
#   @option opts [Boolean] :lossless Enable lossless compression
#   @option opts [Vips::ForeignHeifCompression] :compression Compression format
#   @option opts [Integer] :effort CPU effort
#   @option opts [Vips::ForeignSubsample] :subsample_mode Select chroma subsample operation mode
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [VipsBlob] Buffer to save to

# @!method heifsave_target(target, **opts)
#   Save image in heif format.
#   @param target [Vips::Target] Target to save to
#   @param opts [Hash] Set of options
#   @option opts [Integer] :Q Q factor
#   @option opts [Boolean] :lossless Enable lossless compression
#   @option opts [Vips::ForeignHeifCompression] :compression Compression format
#   @option opts [Integer] :effort CPU effort
#   @option opts [Vips::ForeignSubsample] :subsample_mode Select chroma subsample operation mode
#   @option opts [Boolean] :strip Strip all metadata from image
#   @option opts [Array<Double>] :background Background value
#   @option opts [Integer] :page_height Set page height for multipage save
#   @return [nil] 

# @!method self.thumbnail(filename, width, **opts)
#   Generate thumbnail from file.
#   @param filename [String] Filename to read from
#   @param width [Integer] Size to this width
#   @param opts [Hash] Set of options
#   @option opts [Integer] :height Size to this height
#   @option opts [Vips::Size] :size Only upsize, only downsize, or both
#   @option opts [Boolean] :no_rotate Don't use orientation tags to rotate image upright
#   @option opts [Vips::Interesting] :crop Reduce to fill target rectangle, then crop
#   @option opts [Boolean] :linear Reduce in linear light
#   @option opts [String] :import_profile Fallback import profile
#   @option opts [String] :export_profile Fallback export profile
#   @option opts [Vips::Intent] :intent Rendering intent
#   @return [Vips::Image] Output image

# @!method self.thumbnail_buffer(buffer, width, **opts)
#   Generate thumbnail from buffer.
#   @param buffer [VipsBlob] Buffer to load from
#   @param width [Integer] Size to this width
#   @param opts [Hash] Set of options
#   @option opts [String] :option_string Options that are passed on to the underlying loader
#   @option opts [Integer] :height Size to this height
#   @option opts [Vips::Size] :size Only upsize, only downsize, or both
#   @option opts [Boolean] :no_rotate Don't use orientation tags to rotate image upright
#   @option opts [Vips::Interesting] :crop Reduce to fill target rectangle, then crop
#   @option opts [Boolean] :linear Reduce in linear light
#   @option opts [String] :import_profile Fallback import profile
#   @option opts [String] :export_profile Fallback export profile
#   @option opts [Vips::Intent] :intent Rendering intent
#   @return [Vips::Image] Output image

# @!method thumbnail_image(width, **opts)
#   Generate thumbnail from image.
#   @param width [Integer] Size to this width
#   @param opts [Hash] Set of options
#   @option opts [Integer] :height Size to this height
#   @option opts [Vips::Size] :size Only upsize, only downsize, or both
#   @option opts [Boolean] :no_rotate Don't use orientation tags to rotate image upright
#   @option opts [Vips::Interesting] :crop Reduce to fill target rectangle, then crop
#   @option opts [Boolean] :linear Reduce in linear light
#   @option opts [String] :import_profile Fallback import profile
#   @option opts [String] :export_profile Fallback export profile
#   @option opts [Vips::Intent] :intent Rendering intent
#   @return [Vips::Image] Output image

# @!method self.thumbnail_source(source, width, **opts)
#   Generate thumbnail from source.
#   @param source [Vips::Source] Source to load from
#   @param width [Integer] Size to this width
#   @param opts [Hash] Set of options
#   @option opts [String] :option_string Options that are passed on to the underlying loader
#   @option opts [Integer] :height Size to this height
#   @option opts [Vips::Size] :size Only upsize, only downsize, or both
#   @option opts [Boolean] :no_rotate Don't use orientation tags to rotate image upright
#   @option opts [Vips::Interesting] :crop Reduce to fill target rectangle, then crop
#   @option opts [Boolean] :linear Reduce in linear light
#   @option opts [String] :import_profile Fallback import profile
#   @option opts [String] :export_profile Fallback export profile
#   @option opts [Vips::Intent] :intent Rendering intent
#   @return [Vips::Image] Output image

# @!method mapim(index, **opts)
#   Resample with a map image.
#   @param index [Vips::Image] Index pixels with this
#   @param opts [Hash] Set of options
#   @option opts [Vips::Interpolate] :interpolate Interpolate pixels with this
#   @return [Vips::Image] Output image

# @!method shrink(hshrink, vshrink, **opts)
#   Shrink an image.
#   @param hshrink [Float] Horizontal shrink factor
#   @param vshrink [Float] Vertical shrink factor
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method shrinkh(hshrink, **opts)
#   Shrink an image horizontally.
#   @param hshrink [Integer] Horizontal shrink factor
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method shrinkv(vshrink, **opts)
#   Shrink an image vertically.
#   @param vshrink [Integer] Vertical shrink factor
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method reduceh(hshrink, **opts)
#   Shrink an image horizontally.
#   @param hshrink [Float] Horizontal shrink factor
#   @param opts [Hash] Set of options
#   @option opts [Vips::Kernel] :kernel Resampling kernel
#   @return [Vips::Image] Output image

# @!method reducev(vshrink, **opts)
#   Shrink an image vertically.
#   @param vshrink [Float] Vertical shrink factor
#   @param opts [Hash] Set of options
#   @option opts [Vips::Kernel] :kernel Resampling kernel
#   @return [Vips::Image] Output image

# @!method reduce(hshrink, vshrink, **opts)
#   Reduce an image.
#   @param hshrink [Float] Horizontal shrink factor
#   @param vshrink [Float] Vertical shrink factor
#   @param opts [Hash] Set of options
#   @option opts [Vips::Kernel] :kernel Resampling kernel
#   @return [Vips::Image] Output image

# @!method quadratic(coeff, **opts)
#   Resample an image with a quadratic transform.
#   @param coeff [Vips::Image] Coefficient matrix
#   @param opts [Hash] Set of options
#   @option opts [Vips::Interpolate] :interpolate Interpolate values with this
#   @return [Vips::Image] Output image

# @!method affine(matrix, **opts)
#   Affine transform of an image.
#   @param matrix [Array<Double>] Transformation matrix
#   @param opts [Hash] Set of options
#   @option opts [Vips::Interpolate] :interpolate Interpolate pixels with this
#   @option opts [Array<Integer>] :oarea Area of output to generate
#   @option opts [Float] :odx Horizontal output displacement
#   @option opts [Float] :ody Vertical output displacement
#   @option opts [Float] :idx Horizontal input displacement
#   @option opts [Float] :idy Vertical input displacement
#   @option opts [Array<Double>] :background Background value
#   @option opts [Boolean] :premultiplied Images have premultiplied alpha
#   @option opts [Vips::Extend] :extend How to generate the extra pixels
#   @return [Vips::Image] Output image

# @!method similarity(**opts)
#   Similarity transform of an image.
#   @param opts [Hash] Set of options
#   @option opts [Float] :scale Scale by this factor
#   @option opts [Float] :angle Rotate anticlockwise by this many degrees
#   @option opts [Vips::Interpolate] :interpolate Interpolate pixels with this
#   @option opts [Array<Double>] :background Background value
#   @option opts [Float] :odx Horizontal output displacement
#   @option opts [Float] :ody Vertical output displacement
#   @option opts [Float] :idx Horizontal input displacement
#   @option opts [Float] :idy Vertical input displacement
#   @return [Vips::Image] Output image

# @!method rotate(angle, **opts)
#   Rotate an image by a number of degrees.
#   @param angle [Float] Rotate anticlockwise by this many degrees
#   @param opts [Hash] Set of options
#   @option opts [Vips::Interpolate] :interpolate Interpolate pixels with this
#   @option opts [Array<Double>] :background Background value
#   @option opts [Float] :odx Horizontal output displacement
#   @option opts [Float] :ody Vertical output displacement
#   @option opts [Float] :idx Horizontal input displacement
#   @option opts [Float] :idy Vertical input displacement
#   @return [Vips::Image] Output image

# @!method resize(scale, **opts)
#   Resize an image.
#   @param scale [Float] Scale image by this factor
#   @param opts [Hash] Set of options
#   @option opts [Vips::Kernel] :kernel Resampling kernel
#   @option opts [Float] :vscale Vertical scale image by this factor
#   @return [Vips::Image] Output image

# @!method colourspace(space, **opts)
#   Convert to a new colorspace.
#   @param space [Vips::Interpretation] Destination color space
#   @param opts [Hash] Set of options
#   @option opts [Vips::Interpretation] :source_space Source color space
#   @return [Vips::Image] Output image

# @!method Lab2XYZ(**opts)
#   Transform cielab to xyz.
#   @param opts [Hash] Set of options
#   @option opts [Array<Double>] :temp Color temperature
#   @return [Vips::Image] Output image

# @!method XYZ2Lab(**opts)
#   Transform xyz to lab.
#   @param opts [Hash] Set of options
#   @option opts [Array<Double>] :temp Colour temperature
#   @return [Vips::Image] Output image

# @!method Lab2LCh(**opts)
#   Transform lab to lch.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method LCh2Lab(**opts)
#   Transform lch to lab.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method LCh2CMC(**opts)
#   Transform lch to cmc.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method CMC2LCh(**opts)
#   Transform lch to cmc.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method XYZ2Yxy(**opts)
#   Transform xyz to yxy.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method Yxy2XYZ(**opts)
#   Transform yxy to xyz.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method scRGB2XYZ(**opts)
#   Transform scrgb to xyz.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method XYZ2scRGB(**opts)
#   Transform xyz to scrgb.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method LabQ2Lab(**opts)
#   Unpack a labq image to float lab.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method Lab2LabQ(**opts)
#   Transform float lab to labq coding.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method LabQ2LabS(**opts)
#   Unpack a labq image to short lab.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method LabS2LabQ(**opts)
#   Transform short lab to labq coding.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method LabS2Lab(**opts)
#   Transform signed short lab to float.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method Lab2LabS(**opts)
#   Transform float lab to signed short.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method rad2float(**opts)
#   Unpack radiance coding to float rgb.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method float2rad(**opts)
#   Transform float rgb to radiance coding.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method LabQ2sRGB(**opts)
#   Convert a labq image to srgb.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method sRGB2HSV(**opts)
#   Transform srgb to hsv.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method HSV2sRGB(**opts)
#   Transform hsv to srgb.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method icc_import(**opts)
#   Import from device with icc profile.
#   @param opts [Hash] Set of options
#   @option opts [Vips::PCS] :pcs Set Profile Connection Space
#   @option opts [Vips::Intent] :intent Rendering intent
#   @option opts [Boolean] :black_point_compensation Enable black point compensation
#   @option opts [Boolean] :embedded Use embedded input profile, if available
#   @option opts [String] :input_profile Filename to load input profile from
#   @return [Vips::Image] Output image

# @!method icc_export(**opts)
#   Output to device with icc profile.
#   @param opts [Hash] Set of options
#   @option opts [Vips::PCS] :pcs Set Profile Connection Space
#   @option opts [Vips::Intent] :intent Rendering intent
#   @option opts [Boolean] :black_point_compensation Enable black point compensation
#   @option opts [String] :output_profile Filename to load output profile from
#   @option opts [Integer] :depth Output device space depth in bits
#   @return [Vips::Image] Output image

# @!method icc_transform(output_profile, **opts)
#   Transform between devices with icc profiles.
#   @param output_profile [String] Filename to load output profile from
#   @param opts [Hash] Set of options
#   @option opts [Vips::PCS] :pcs Set Profile Connection Space
#   @option opts [Vips::Intent] :intent Rendering intent
#   @option opts [Boolean] :black_point_compensation Enable black point compensation
#   @option opts [Boolean] :embedded Use embedded input profile, if available
#   @option opts [String] :input_profile Filename to load input profile from
#   @option opts [Integer] :depth Output device space depth in bits
#   @return [Vips::Image] Output image

# @!method dE76(right, **opts)
#   Calculate de76.
#   @param right [Vips::Image] Right-hand input image
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method dE00(right, **opts)
#   Calculate de00.
#   @param right [Vips::Image] Right-hand input image
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method dECMC(right, **opts)
#   Calculate decmc.
#   @param right [Vips::Image] Right-hand input image
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method sRGB2scRGB(**opts)
#   Convert an srgb image to scrgb.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method scRGB2BW(**opts)
#   Convert scrgb to bw.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :depth Output device space depth in bits
#   @return [Vips::Image] Output image

# @!method scRGB2sRGB(**opts)
#   Convert an scrgb image to srgb.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :depth Output device space depth in bits
#   @return [Vips::Image] Output image

# @!method CMYK2XYZ(**opts)
#   Transform cmyk to xyz.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method XYZ2CMYK(**opts)
#   Transform xyz to cmyk.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method self.profile_load(name, **opts)
#   Load named icc profile.
#   @param name [String] Profile name
#   @param opts [Hash] Set of options
#   @return [VipsBlob] Loaded profile

# @!method maplut(lut, **opts)
#   Map an image though a lut.
#   @param lut [Vips::Image] Look-up table image
#   @param opts [Hash] Set of options
#   @option opts [Integer] :band apply one-band lut to this band of in
#   @return [Vips::Image] Output image

# @!method case(cases, **opts)
#   Use pixel values to pick cases from an array of images.
#   @param cases [Array<Image>] Array of case images
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method percent(percent, **opts)
#   Find threshold for percent of pixels.
#   @param percent [Float] Percent of pixels
#   @param opts [Hash] Set of options
#   @return [Integer] Threshold above which lie percent of pixels

# @!method stdif(width, height, **opts)
#   Statistical difference.
#   @param width [Integer] Window width in pixels
#   @param height [Integer] Window height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Float] :s0 New deviation
#   @option opts [Float] :b Weight of new deviation
#   @option opts [Float] :m0 New mean
#   @option opts [Float] :a Weight of new mean
#   @return [Vips::Image] Output image

# @!method hist_cum(**opts)
#   Form cumulative histogram.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method hist_match(ref, **opts)
#   Match two histograms.
#   @param ref [Vips::Image] Reference histogram
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method hist_norm(**opts)
#   Normalise histogram.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method hist_equal(**opts)
#   Histogram equalisation.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :band Equalise with this band
#   @return [Vips::Image] Output image

# @!method hist_plot(**opts)
#   Plot histogram.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method hist_local(width, height, **opts)
#   Local histogram equalisation.
#   @param width [Integer] Window width in pixels
#   @param height [Integer] Window height in pixels
#   @param opts [Hash] Set of options
#   @option opts [Integer] :max_slope Maximum slope (CLAHE)
#   @return [Vips::Image] Output image

# @!method hist_ismonotonic(**opts)
#   Test for monotonicity.
#   @param opts [Hash] Set of options
#   @return [Boolean] true if in is monotonic

# @!method hist_entropy(**opts)
#   Estimate image entropy.
#   @param opts [Hash] Set of options
#   @return [Float] Output value

# @!method conv(mask, **opts)
#   Convolution operation.
#   @param mask [Vips::Image] Input matrix image
#   @param opts [Hash] Set of options
#   @option opts [Vips::Precision] :precision Convolve with this precision
#   @option opts [Integer] :layers Use this many layers in approximation
#   @option opts [Integer] :cluster Cluster lines closer than this in approximation
#   @return [Vips::Image] Output image

# @!method conva(mask, **opts)
#   Approximate integer convolution.
#   @param mask [Vips::Image] Input matrix image
#   @param opts [Hash] Set of options
#   @option opts [Integer] :layers Use this many layers in approximation
#   @option opts [Integer] :cluster Cluster lines closer than this in approximation
#   @return [Vips::Image] Output image

# @!method convf(mask, **opts)
#   Float convolution operation.
#   @param mask [Vips::Image] Input matrix image
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method convi(mask, **opts)
#   Int convolution operation.
#   @param mask [Vips::Image] Input matrix image
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method compass(mask, **opts)
#   Convolve with rotating mask.
#   @param mask [Vips::Image] Input matrix image
#   @param opts [Hash] Set of options
#   @option opts [Integer] :times Rotate and convolve this many times
#   @option opts [Vips::Angle45] :angle Rotate mask by this much between convolutions
#   @option opts [Vips::Combine] :combine Combine convolution results like this
#   @option opts [Vips::Precision] :precision Convolve with this precision
#   @option opts [Integer] :layers Use this many layers in approximation
#   @option opts [Integer] :cluster Cluster lines closer than this in approximation
#   @return [Vips::Image] Output image

# @!method convsep(mask, **opts)
#   Seperable convolution operation.
#   @param mask [Vips::Image] Input matrix image
#   @param opts [Hash] Set of options
#   @option opts [Vips::Precision] :precision Convolve with this precision
#   @option opts [Integer] :layers Use this many layers in approximation
#   @option opts [Integer] :cluster Cluster lines closer than this in approximation
#   @return [Vips::Image] Output image

# @!method convasep(mask, **opts)
#   Approximate separable integer convolution.
#   @param mask [Vips::Image] Input matrix image
#   @param opts [Hash] Set of options
#   @option opts [Integer] :layers Use this many layers in approximation
#   @return [Vips::Image] Output image

# @!method fastcor(ref, **opts)
#   Fast correlation.
#   @param ref [Vips::Image] Input reference image
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method spcor(ref, **opts)
#   Spatial correlation.
#   @param ref [Vips::Image] Input reference image
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method sharpen(**opts)
#   Unsharp masking for print.
#   @param opts [Hash] Set of options
#   @option opts [Float] :sigma Sigma of Gaussian
#   @option opts [Float] :x1 Flat/jaggy threshold
#   @option opts [Float] :y2 Maximum brightening
#   @option opts [Float] :y3 Maximum darkening
#   @option opts [Float] :m1 Slope for flat areas
#   @option opts [Float] :m2 Slope for jaggy areas
#   @return [Vips::Image] Output image

# @!method gaussblur(sigma, **opts)
#   Gaussian blur.
#   @param sigma [Float] Sigma of Gaussian
#   @param opts [Hash] Set of options
#   @option opts [Float] :min_ampl Minimum amplitude of Gaussian
#   @option opts [Vips::Precision] :precision Convolve with this precision
#   @return [Vips::Image] Output image

# @!method canny(**opts)
#   Canny edge detector.
#   @param opts [Hash] Set of options
#   @option opts [Float] :sigma Sigma of Gaussian
#   @option opts [Vips::Precision] :precision Convolve with this precision
#   @return [Vips::Image] Output image

# @!method sobel(**opts)
#   Sobel edge detector.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method fwfft(**opts)
#   Forward fft.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method invfft(**opts)
#   Inverse fft.
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :real Output only the real part of the transform
#   @return [Vips::Image] Output image

# @!method freqmult(mask, **opts)
#   Frequency-domain filtering.
#   @param mask [Vips::Image] Input mask image
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method spectrum(**opts)
#   Make displayable power spectrum.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method phasecor(in2, **opts)
#   Calculate phase correlation.
#   @param in2 [Vips::Image] Second input image
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method morph(mask, morph, **opts)
#   Morphology operation.
#   @param mask [Vips::Image] Input matrix image
#   @param morph [Vips::OperationMorphology] Morphological operation to perform
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method rank(width, height, index, **opts)
#   Rank filter.
#   @param width [Integer] Window width in pixels
#   @param height [Integer] Window height in pixels
#   @param index [Integer] Select pixel at index
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output image

# @!method countlines(direction, **opts)
#   Count lines in an image.
#   @param direction [Vips::Direction] Countlines left-right or up-down
#   @param opts [Hash] Set of options
#   @return [Float] Number of lines

# @!method labelregions(**opts)
#   Label regions in an image.
#   @param opts [Hash] Set of options
#   @option opts [Integer] :segments Output Number of discrete contigious regions
#   @return [Vips::Image, Hash<Symbol => Object>] Mask of region labels, Hash of optional output items

# @!method fill_nearest(**opts)
#   Fill image zeros with nearest non-zero pixel.
#   @param opts [Hash] Set of options
#   @option opts [Vips::Image] :distance Output Distance to nearest non-zero pixel
#   @return [Vips::Image, Hash<Symbol => Object>] Value of nearest non-zero pixel, Hash of optional output items

# @!method draw_rect(ink, left, top, width, height, **opts)
#   Paint a rectangle on an image.
#   @param ink [Array<Double>] Color for pixels
#   @param left [Integer] Rect to fill
#   @param top [Integer] Rect to fill
#   @param width [Integer] Rect to fill
#   @param height [Integer] Rect to fill
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :fill Draw a solid object
#   @return [Vips::Image] Image to draw on

# @!method draw_mask(ink, mask, x, y, **opts)
#   Draw a mask on an image.
#   @param ink [Array<Double>] Color for pixels
#   @param mask [Vips::Image] Mask of pixels to draw
#   @param x [Integer] Draw mask here
#   @param y [Integer] Draw mask here
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Image to draw on

# @!method draw_line(ink, x1, y1, x2, y2, **opts)
#   Draw a line on an image.
#   @param ink [Array<Double>] Color for pixels
#   @param x1 [Integer] Start of draw_line
#   @param y1 [Integer] Start of draw_line
#   @param x2 [Integer] End of draw_line
#   @param y2 [Integer] End of draw_line
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Image to draw on

# @!method draw_circle(ink, cx, cy, radius, **opts)
#   Draw a circle on an image.
#   @param ink [Array<Double>] Color for pixels
#   @param cx [Integer] Centre of draw_circle
#   @param cy [Integer] Centre of draw_circle
#   @param radius [Integer] Radius in pixels
#   @param opts [Hash] Set of options
#   @option opts [Boolean] :fill Draw a solid object
#   @return [Vips::Image] Image to draw on

# @!method draw_flood(ink, x, y, **opts)
#   Flood-fill an area.
#   @param ink [Array<Double>] Color for pixels
#   @param x [Integer] DrawFlood start point
#   @param y [Integer] DrawFlood start point
#   @param opts [Hash] Set of options
#   @option opts [Vips::Image] :test Test pixels in this image
#   @option opts [Boolean] :equal DrawFlood while equal to edge
#   @option opts [Integer] :left Output Left edge of modified area
#   @option opts [Integer] :top Output top edge of modified area
#   @option opts [Integer] :width Output width of modified area
#   @option opts [Integer] :height Output height of modified area
#   @return [Vips::Image, Hash<Symbol => Object>] Image to draw on, Hash of optional output items

# @!method draw_image(sub, x, y, **opts)
#   Paint an image into another image.
#   @param sub [Vips::Image] Sub-image to insert into main image
#   @param x [Integer] Draw image here
#   @param y [Integer] Draw image here
#   @param opts [Hash] Set of options
#   @option opts [Vips::CombineMode] :mode Combining mode
#   @return [Vips::Image] Image to draw on

# @!method draw_smudge(left, top, width, height, **opts)
#   Blur a rectangle on an image.
#   @param left [Integer] Rect to fill
#   @param top [Integer] Rect to fill
#   @param width [Integer] Rect to fill
#   @param height [Integer] Rect to fill
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Image to draw on

# @!method merge(sec, direction, dx, dy, **opts)
#   Merge two images.
#   @param sec [Vips::Image] Secondary image
#   @param direction [Vips::Direction] Horizontal or vertical merge
#   @param dx [Integer] Horizontal displacement from sec to ref
#   @param dy [Integer] Vertical displacement from sec to ref
#   @param opts [Hash] Set of options
#   @option opts [Integer] :mblend Maximum blend size
#   @return [Vips::Image] Output image

# @!method mosaic(sec, direction, xref, yref, xsec, ysec, **opts)
#   Mosaic two images.
#   @param sec [Vips::Image] Secondary image
#   @param direction [Vips::Direction] Horizontal or vertical mosaic
#   @param xref [Integer] Position of reference tie-point
#   @param yref [Integer] Position of reference tie-point
#   @param xsec [Integer] Position of secondary tie-point
#   @param ysec [Integer] Position of secondary tie-point
#   @param opts [Hash] Set of options
#   @option opts [Integer] :hwindow Half window size
#   @option opts [Integer] :harea Half area size
#   @option opts [Integer] :mblend Maximum blend size
#   @option opts [Integer] :bandno Band to search for features on
#   @option opts [Integer] :dx0 Output Detected integer offset
#   @option opts [Integer] :dy0 Output Detected integer offset
#   @option opts [Float] :scale1 Output Detected scale
#   @option opts [Float] :angle1 Output Detected rotation
#   @option opts [Float] :dy1 Output Detected first-order displacement
#   @option opts [Float] :dx1 Output Detected first-order displacement
#   @return [Vips::Image, Hash<Symbol => Object>] Output image, Hash of optional output items

# @!method mosaic1(sec, direction, xr1, yr1, xs1, ys1, xr2, yr2, xs2, ys2, **opts)
#   First-order mosaic of two images.
#   @param sec [Vips::Image] Secondary image
#   @param direction [Vips::Direction] Horizontal or vertical mosaic
#   @param xr1 [Integer] Position of first reference tie-point
#   @param yr1 [Integer] Position of first reference tie-point
#   @param xs1 [Integer] Position of first secondary tie-point
#   @param ys1 [Integer] Position of first secondary tie-point
#   @param xr2 [Integer] Position of second reference tie-point
#   @param yr2 [Integer] Position of second reference tie-point
#   @param xs2 [Integer] Position of second secondary tie-point
#   @param ys2 [Integer] Position of second secondary tie-point
#   @param opts [Hash] Set of options
#   @option opts [Integer] :hwindow Half window size
#   @option opts [Integer] :harea Half area size
#   @option opts [Boolean] :search Search to improve tie-points
#   @option opts [Vips::Interpolate] :interpolate Interpolate pixels with this
#   @option opts [Integer] :mblend Maximum blend size
#   @option opts [Integer] :bandno Band to search for features on
#   @return [Vips::Image] Output image

# @!method matrixinvert(**opts)
#   Invert an matrix.
#   @param opts [Hash] Set of options
#   @return [Vips::Image] Output matrix

# @!method match(sec, xr1, yr1, xs1, ys1, xr2, yr2, xs2, ys2, **opts)
#   First-order match of two images.
#   @param sec [Vips::Image] Secondary image
#   @param xr1 [Integer] Position of first reference tie-point
#   @param yr1 [Integer] Position of first reference tie-point
#   @param xs1 [Integer] Position of first secondary tie-point
#   @param ys1 [Integer] Position of first secondary tie-point
#   @param xr2 [Integer] Position of second reference tie-point
#   @param yr2 [Integer] Position of second reference tie-point
#   @param xs2 [Integer] Position of second secondary tie-point
#   @param ys2 [Integer] Position of second secondary tie-point
#   @param opts [Hash] Set of options
#   @option opts [Integer] :hwindow Half window size
#   @option opts [Integer] :harea Half area size
#   @option opts [Boolean] :search Search to improve tie-points
#   @option opts [Vips::Interpolate] :interpolate Interpolate pixels with this
#   @return [Vips::Image] Output image

# @!method globalbalance(**opts)
#   Global balance an image mosaic.
#   @param opts [Hash] Set of options
#   @option opts [Float] :gamma Image gamma
#   @option opts [Boolean] :int_output Integer output
#   @return [Vips::Image] Output image

  end
end
