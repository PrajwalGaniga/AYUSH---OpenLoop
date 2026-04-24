from datetime import datetime

# A simplified mapper for Indian seasons (Ritus) based on Gregorian months
# Since region can vary, this is a generalized map for the Indian subcontinent.

def get_current_ritu(region: str = "India") -> str:
    """
    Returns the current Ayurvedic season (Ritu) based on the current month.
    """
    month = datetime.now().month

    if month in (1, 2):
        return "Shishira (Late Winter)"
    elif month in (3, 4):
        return "Vasanta (Spring)"
    elif month in (5, 6):
        return "Grishma (Summer)"
    elif month in (7, 8):
        return "Varsha (Monsoon)"
    elif month in (9, 10):
        return "Sharad (Autumn)"
    else:  # 11, 12
        return "Hemanta (Early Winter)"

