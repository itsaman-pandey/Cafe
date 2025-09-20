from fastapi import FastAPI, HTTPException, Query
from app import models, schemas
from app.database import Base, engine
from app.routes import auth, products, cart, orders, admin, barista
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app import models, schemas
from app.database import get_db
# Create all tables (only for dev; in prod use Alembic migrations)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Coffee Shop API")

# Routers
app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(products.router, prefix="/products", tags=["Products"])
app.include_router(cart.router, prefix="/cart", tags=["Cart"])
app.include_router(orders.router, prefix="/orders", tags=["Orders"])
app.include_router(admin.router, prefix="/admin", tags=["Admin"])
app.include_router(barista.router, prefix="/barista", tags=["Barista"])


@app.get("/")
def root():
    return {"message": "Welcome to Coffee Shop API ☕"}

@app.get("/user", response_model=schemas.UserPublic)
def get_user_by_email(email: str = Query(...), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return schemas.UserPublic(
        name=user.name,
        email=user.email,
        phone=user.phone,
        address=user.address
    )

@app.put("/user/{email}", response_model=schemas.UserPublic, tags=["Users"])
def update_user(email: str, updated: schemas.UserUpdate, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Update only provided fields
    data = updated.dict(exclude_unset=True)
    for field, value in data.items():
        setattr(user, field, value)

    db.commit()
    db.refresh(user)

    return schemas.UserPublic(
        name=user.name,
        email=user.email,
        phone=user.phone,
        address=user.address
    )
