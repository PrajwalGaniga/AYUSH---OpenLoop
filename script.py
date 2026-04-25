"""
================================================================================
PaddleOCR Detailed Usage Guide
================================================================================

This script demonstrates how to initialize and use PaddleOCR (v2.8.1) for text 
extraction. PaddleOCR is a highly efficient OCR (Optical Character Recognition) 
library developed by Baidu. 

Key advantages of PaddleOCR:
- Lightweight (the default models are around 8-10 MB).
- Extremely fast on CPU.
- Very accurate, especially for printed documents, receipts, and structured text.
- Supports over 80 languages.

--------------------------------------------------------------------------------
Understanding the initialization parameters:
--------------------------------------------------------------------------------
paddle_reader = PaddleOCR(
    use_angle_cls=True,   # If True, the model will try to identify if the text is upside down or rotated 90/180/270 degrees and correct it before reading.
    lang='en',            # The language to recognize. 'en' is English. 'ch' is Chinese.
    use_gpu=False,        # Set to False to run entirely on the CPU. Set to True if you have an NVIDIA GPU + CUDA installed.
    show_log=False        # If False, disables the verbose debug logging that PaddleOCR prints to the terminal by default.
)

--------------------------------------------------------------------------------
Understanding the output structure:
--------------------------------------------------------------------------------
The `.ocr(image_path_or_numpy_array)` method returns a nested list structure.
For a standard image, it returns a list containing one element (for the single image), 
which itself is a list of detected text lines.

Each text line looks like this:
[ 
  [[x1, y1], [x2, y2], [x3, y3], [x4, y4]],  # The bounding box coordinates (4 points defining the polygon surrounding the text)
  ('Detected Text String', 0.987654)         # A tuple containing the extracted string and its confidence score (0.0 to 1.0)
]
"""

import cv2
import numpy as np
from paddleocr import PaddleOCR

def main():
    print("Initializing PaddleOCR...")
    # 1. Initialize the PaddleOCR reader
    # Note: The first time you run this, it will download the lightweight detection 
    # and recognition models to your user directory (~/.paddleocr/).
    ocr = PaddleOCR(
        use_angle_cls=True, 
        lang='en', 
        use_gpu=False, 
        show_log=False
    )
    print("PaddleOCR initialized successfully!\n")

    # 2. Create or load an image
    # For this script, we will dynamically generate an image with text using OpenCV
    # so that the script works out-of-the-box without needing an external image file.
    # If you have an image file, you would just do: image_path = 'my_image.png'
    print("Generating a test image with OpenCV...")
    img = np.ones((200, 600, 3), dtype=np.uint8) * 255  # Create a white background
    cv2.putText(img, 'PaddleOCR is amazing!', (20, 70), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 0, 0), 3)
    cv2.putText(img, 'Confidence: 100%', (20, 140), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (50, 50, 150), 2)
    
    # Save it to disk just so you can see what was analyzed (optional)
    test_image_path = "test_generated_image.jpg"
    cv2.imwrite(test_image_path, img)
    print(f"Test image saved to {test_image_path}\n")

    # 3. Perform OCR on the image
    # You can pass a file path string OR a loaded numpy array (like we do here).
    # cls=True tells the model to use the angle classifier we enabled during initialization.
    print("Running OCR inference...")
    result = ocr.ocr(img, cls=True)

    # 4. Parse the results
    print("\n" + "="*50)
    print("OCR RESULTS PARSING")
    print("="*50)
    
    # PaddleOCR returns a list of lists. result[0] represents the first image passed.
    if result and result[0]:
        lines = result[0]
        print(f"Found {len(lines)} distinct lines of text.\n")
        
        for idx, line in enumerate(lines):
            # Extract the data from the nested structure
            bounding_box = line[0]     # [[x1,y1], [x2,y2], [x3,y3], [x4,y4]]
            text_tuple = line[1]       # ('Detected Text', 0.99)
            
            text_string = text_tuple[0]
            confidence = text_tuple[1]
            
            print(f"--- Line {idx + 1} ---")
            print(f"Text       : {text_string}")
            print(f"Confidence : {confidence:.4f} ({(confidence*100):.1f}%)")
            
            # Format bounding box nicely
            formatted_box = ", ".join([f"({int(pt[0])}, {int(pt[1])})" for pt in bounding_box])
            print(f"Box Points : {formatted_box}\n")
    else:
        print("No text was detected in the image.")

if __name__ == "__main__":
    main()
