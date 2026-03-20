## ADDED Requirements

### Requirement: Pixel data caching uses thread-safe API
The `buildPixelData` method in PaletteExtractionViewModel SHALL use only thread-safe CoreGraphics APIs. It SHALL NOT use UIKit graphics context APIs (`UIGraphicsPushContext`, `UIGraphicsPopContext`, `image.draw(in:)`).

#### Scenario: Pixel data is built off main thread without crash
- **WHEN** a user selects an image and `buildPixelData` executes on a background thread
- **THEN** pixel data is correctly generated using `CGContext.draw(cgImage, in:)` without accessing UIKit thread-local state

#### Scenario: Pixel data dimensions match CGImage pixels
- **WHEN** `buildPixelData` processes an image
- **THEN** it uses `cgImage.width` and `cgImage.height` (pixel dimensions) instead of `image.size` (point dimensions)

#### Scenario: Magnifier color picking works after caching
- **WHEN** pixel data caching completes and user drags on the image
- **THEN** `pickColor(at:)` returns correct colors using the cached pixel buffer

