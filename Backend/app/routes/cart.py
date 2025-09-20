from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user

router = APIRouter()

@router.get("/", response_model=list[schemas.CartItem])
def get_cart(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return db.query(models.Cart).filter(models.Cart.user_id == current_user.id).all()

@router.post("/add/{product_id}")
def add_to_cart(product_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    product = db.query(models.Product).filter(models.Product.id == product_id, models.Product.available == True).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    cart_item = db.query(models.Cart).filter(
        models.Cart.user_id == current_user.id,
        models.Cart.product_id == product_id
    ).first()

    if cart_item:
        cart_item.quantity += 1
    else:
        cart_item = models.Cart(user_id=current_user.id, product_id=product_id, quantity=1)
        db.add(cart_item)

    db.commit()
    return {"message": f"{product.name} added to cart"}

@router.delete("/remove/{cart_id}")
def remove_from_cart(cart_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    item = db.query(models.Cart).filter(models.Cart.id == cart_id, models.Cart.user_id == current_user.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    db.delete(item)
    db.commit()
    return {"message": "Item removed"}
