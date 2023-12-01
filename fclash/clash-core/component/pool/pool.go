package pool

import (
	"context"
	"runtime"
	"time"
)

type Factory = func(context.Context) (any, error)

type entry struct {
	elm  any
	time time.Time
}

type Option func(*pool)

// WithEvict set the evict callback
func WithEvict(cb func(any)) Option {
	return func(p *pool) {
		p.evict = cb
	}
}

// WithAge defined element max age (millisecond)
func WithAge(maxAge int64) Option {
	return func(p *pool) {
		p.maxAge = maxAge
	}
}

// WithSize defined max size of Pool
func WithSize(maxSize int) Option {
	return func(p *pool) {
		p.ch = make(chan any, maxSize)
	}
}

// Pool is for GC, see New for detail
type Pool struct {
	*pool
}

type pool struct {
	ch      chan any
	factory Factory
	evict   func(any)
	maxAge  int64
}

func (p *pool) GetContext(ctx context.Context) (any, error) {
	now := time.Now()
	for {
		select {
		case item := <-p.ch:
			elm := item.(*entry)
			if p.maxAge != 0 && now.Sub(item.(*entry).time).Milliseconds() > p.maxAge {
				if p.evict != nil {
					p.evict(elm.elm)
				}
				continue
			}

			return elm.elm, nil
		default:
			return p.factory(ctx)
		}
	}
}

func (p *pool) Get() (any, error) {
	return p.GetContext(context.Background())
}

func (p *pool) Put(item any) {
	e := &entry{
		elm:  item,
		time: time.Now(),
	}

	select {
	case p.ch <- e:
		return
	default:
		// pool is full
		if p.evict != nil {
			p.evict(item)
		}
		return
	}
}

func recycle(p *Pool) {
	for item := range p.pool.ch {
		if p.pool.evict != nil {
			p.pool.evict(item.(*entry).elm)
		}
	}
}

func New(factory Factory, options ...Option) *Pool {
	p := &pool{
		ch:      make(chan any, 10),
		factory: factory,
	}

	for _, option := range options {
		option(p)
	}

	P := &Pool{p}
	runtime.SetFinalizer(P, recycle)
	return P
}
